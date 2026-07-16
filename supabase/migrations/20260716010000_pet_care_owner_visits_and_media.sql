-- TestFlight fixes for owner-managed pet care, self-reported visits,
-- durable medication notifications, and announcement pet photos.

-- Direct REST mutations still require table privileges in addition to RLS.
grant select, insert, update, delete
  on public.pet_medications, public.pet_feedings, public.pet_achievements
  to authenticated;
revoke all
  on public.pet_medications, public.pet_feedings, public.pet_achievements
  from anon;

alter table public.pet_achievements
  add column if not exists award_image_url text,
  add column if not exists event_photo_url text,
  add column if not exists award_image_path text,
  add column if not exists event_photo_path text;

drop policy if exists "owners manage pet medications" on public.pet_medications;
create policy "owners manage pet medications"
on public.pet_medications for all to authenticated
using (public.owns_pet(pet_id))
with check (public.owns_pet(pet_id));

drop policy if exists "owners manage pet feedings" on public.pet_feedings;
create policy "owners manage pet feedings"
on public.pet_feedings for all to authenticated
using (public.owns_pet(pet_id))
with check (public.owns_pet(pet_id));

drop policy if exists "owners manage pet achievements" on public.pet_achievements;
create policy "owners manage pet achievements"
on public.pet_achievements for all to authenticated
using (public.owns_pet(pet_id))
with check (public.owns_pet(pet_id));

-- The mobile product uses an owner-managed medical journal. Clinic columns are
-- retained only for backward compatibility with existing rows.
alter table public.visit_records
  add column if not exists provider_name text,
  alter column clinic_id drop not null,
  drop constraint if exists visit_records_status_check,
  add constraint visit_records_status_check
    check (status in ('draft', 'published', 'archived', 'self_reported'));

drop policy if exists "owners and clinic staff read visit records"
  on public.visit_records;
drop policy if exists "owners read own visit records"
  on public.visit_records;
drop policy if exists "clinic staff create visit records"
  on public.visit_records;
drop policy if exists "clinic staff update visit records"
  on public.visit_records;
create policy "owners read own visit records"
on public.visit_records for select to authenticated
using (
  public.is_platform_admin()
  or (status in ('published', 'self_reported') and public.owns_pet(pet_id))
);

drop policy if exists "owners create self reported visit records"
  on public.visit_records;
create policy "owners create self reported visit records"
on public.visit_records for insert to authenticated
with check (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.owns_pet(pet_id)
  and clinic_id is null
  and doctor_id is null
  and appointment_id is null
  and status = 'self_reported'
  and internal_notes is null
);

drop policy if exists "owners update self reported visit records"
  on public.visit_records;
create policy "owners update self reported visit records"
on public.visit_records for update to authenticated
using (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.owns_pet(pet_id)
  and status = 'self_reported'
)
with check (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.owns_pet(pet_id)
  and clinic_id is null
  and doctor_id is null
  and appointment_id is null
  and status = 'self_reported'
  and internal_notes is null
);

drop policy if exists "owners delete self reported visit records"
  on public.visit_records;
create policy "owners delete self reported visit records"
on public.visit_records for delete to authenticated
using (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.owns_pet(pet_id)
  and status = 'self_reported'
);

create or replace function public.can_access_visit_record(
  target_visit_record_id uuid
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.visit_records
    where id = target_visit_record_id
      and (
        public.is_platform_admin()
        or (
          status in ('published', 'self_reported')
          and public.owns_pet(pet_id)
        )
      )
  );
$$;

revoke select on table public.visit_records from authenticated;
grant select (
  id, appointment_id, clinic_id, doctor_id, pet_id, created_by, visit_date,
  reason, diagnosis, treatment_notes, recommendations, follow_up_at, status,
  created_at, updated_at, owner_id, reason_for_visit, symptoms,
  procedures_performed, prescribed_medications, next_visit_recommended,
  next_visit_date, provider_name
) on table public.visit_records to authenticated;

grant insert (
  pet_id, owner_id, created_by, visit_date, reason, reason_for_visit,
  provider_name, symptoms, diagnosis, treatment_notes,
  prescribed_medications, recommendations, next_visit_recommended,
  next_visit_date, status
) on table public.visit_records to authenticated;

revoke update, delete on table public.visit_records from authenticated;
grant update (
  visit_date, reason, reason_for_visit, provider_name, symptoms, diagnosis,
  treatment_notes, prescribed_medications, recommendations,
  next_visit_recommended, next_visit_date, updated_at
) on table public.visit_records to authenticated;
grant delete on table public.visit_records to authenticated;

-- Add a durable in-app notification when an owner schedules a medication.
alter table public.notifications
  drop constraint if exists notifications_type_check,
  add constraint notifications_type_check check (
    type in (
      'appointment_created', 'appointment_confirmed',
      'appointment_cancelled_by_clinic', 'appointment_reminder_24h',
      'appointment_reminder_2h', 'visit_record_published',
      'document_uploaded', 'next_visit_recommended', 'review_request',
      'clinic_message_placeholder', 'new_appointment_request',
      'appointment_cancelled_by_owner', 'appointment_upcoming_today',
      'visit_record_missing', 'review_received',
      'subscription_limit_warning', 'subscription_upgrade_request_status',
      'pet_transfer_request', 'medication_reminder'
    )
  );

create or replace function public.sync_medication_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_record record;
  pet_name text;
begin
  update public.notifications
  set status = 'archived', updated_at = now()
  where type = 'medication_reminder'
    and data->>'medication_id' = new.id::text
    and status <> 'archived';

  if new.reminder_enabled is not true or new.next_dose_date is null then
    return new;
  end if;

  select name into pet_name from public.pets where id = new.pet_id;

  for owner_record in
    select distinct user_id
    from public.pet_owners
    where pet_id = new.pet_id
  loop
    perform public.create_notification(
      owner_record.user_id,
      'medication_reminder',
      'Нагадування про препарат',
      coalesce(pet_name, 'Тварина') || ': ' || new.name ||
        ' — ' || to_char(new.next_dose_date, 'DD.MM.YYYY'),
      null,
      new.pet_id,
      null,
      null,
      null,
      null,
      jsonb_build_object(
        'medication_id', new.id,
        'pet_name', pet_name,
        'next_dose_date', new.next_dose_date
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists sync_medication_notification
  on public.pet_medications;
create trigger sync_medication_notification
after insert or update of name, next_dose_date, reminder_enabled
on public.pet_medications
for each row execute function public.sync_medication_notification();

-- Announcements always inherit the current private pet image path.
create or replace function public.fill_announcement_pet_photo()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.pet_id is not null then
    select coalesce(new.photo_storage_path, pets.avatar_storage_path),
           coalesce(new.photo_url, pets.avatar_url)
      into new.photo_storage_path, new.photo_url
    from public.pets
    where pets.id = new.pet_id;
  end if;
  return new;
end;
$$;

drop trigger if exists fill_announcement_pet_photo on public.announcements;
create trigger fill_announcement_pet_photo
before insert or update of pet_id, photo_storage_path, photo_url
on public.announcements
for each row execute function public.fill_announcement_pet_photo();

create or replace function public.sync_pet_photo_to_announcements()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.announcements
  set photo_storage_path = new.avatar_storage_path,
      photo_url = new.avatar_url,
      updated_at = now()
  where pet_id = new.id;
  return new;
end;
$$;

drop trigger if exists sync_pet_photo_to_announcements on public.pets;
create trigger sync_pet_photo_to_announcements
after update of avatar_storage_path, avatar_url on public.pets
for each row execute function public.sync_pet_photo_to_announcements();

update public.announcements announcement
set photo_storage_path = coalesce(
      announcement.photo_storage_path,
      pet.avatar_storage_path
    ),
    photo_url = coalesce(announcement.photo_url, pet.avatar_url),
    updated_at = now()
from public.pets pet
where announcement.pet_id = pet.id
  and (
    announcement.photo_storage_path is null
    or announcement.photo_url is null
  );
