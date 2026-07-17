-- Keep medication data and reminders scoped to the pet's current primary owner.
-- Also repairs older production tables where the update trigger existed before
-- the updated_at column was added.

alter table public.pet_medications
  add column if not exists updated_at timestamptz not null default now();

alter table public.pet_achievements
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists event_photo_url text,
  add column if not exists award_image_path text,
  add column if not exists event_photo_path text;

alter table public.pet_feedings
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.current_user_is_primary_pet_owner(
  target_pet_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.pets pet
    where pet.id = target_pet_id
      and pet.owner_id = auth.uid()
  );
$$;

revoke all on function public.current_user_is_primary_pet_owner(uuid)
  from public, anon;
grant execute on function public.current_user_is_primary_pet_owner(uuid)
  to authenticated;

drop policy if exists "owners manage pet medications"
  on public.pet_medications;
create policy "owners manage pet medications"
on public.pet_medications for all to authenticated
using (public.current_user_is_primary_pet_owner(pet_id))
with check (public.current_user_is_primary_pet_owner(pet_id));

drop policy if exists "owners manage pet achievements"
  on public.pet_achievements;
create policy "owners manage pet achievements"
on public.pet_achievements for all to authenticated
using (public.current_user_is_primary_pet_owner(pet_id))
with check (public.current_user_is_primary_pet_owner(pet_id));

drop policy if exists "owners manage pet feedings"
  on public.pet_feedings;
create policy "owners manage pet feedings"
on public.pet_feedings for all to authenticated
using (public.current_user_is_primary_pet_owner(pet_id))
with check (public.current_user_is_primary_pet_owner(pet_id));

-- Announcement mutations must also belong to the pet's current primary owner.
-- This avoids stale pet_owners rows blocking or authorizing an edit.
drop policy if exists "owners create announcements" on public.announcements;
create policy "owners create announcements"
on public.announcements for insert to authenticated
with check (
  owner_id = auth.uid()
  and public.current_user_is_primary_pet_owner(pet_id)
  and moderation_status = 'published'
);

drop policy if exists "owners update announcements" on public.announcements;
create policy "owners update announcements"
on public.announcements for update to authenticated
using (
  owner_id = auth.uid()
  and public.current_user_is_primary_pet_owner(pet_id)
)
with check (
  owner_id = auth.uid()
  and public.current_user_is_primary_pet_owner(pet_id)
);

drop policy if exists "owners create transfers" on public.pet_transfers;
create policy "owners create transfers"
on public.pet_transfers for insert to authenticated
with check (
  from_user_id = auth.uid()
  and public.current_user_is_primary_pet_owner(pet_id)
  and status = 'pending'
  and lower(to_email) <> lower(coalesce(auth.jwt()->>'email', ''))
);

-- Private pet media follows the same primary-owner rule as the records it
-- belongs to. Published announcement photos retain their separate read policy.
drop policy if exists "owners read private pet files" on storage.objects;
create policy "owners read private pet files"
on storage.objects for select to authenticated
using (
  bucket_id = 'pet-documents'
  and public.current_user_is_primary_pet_owner(
    public.pet_id_from_storage_path(name)
  )
);

drop policy if exists "owners upload private pet files" on storage.objects;
create policy "owners upload private pet files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_user_is_primary_pet_owner(
    public.pet_id_from_storage_path(name)
  )
);

drop policy if exists "owners update private pet files" on storage.objects;
create policy "owners update private pet files"
on storage.objects for update to authenticated
using (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_user_is_primary_pet_owner(
    public.pet_id_from_storage_path(name)
  )
)
with check (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_user_is_primary_pet_owner(
    public.pet_id_from_storage_path(name)
  )
);

drop policy if exists "owners delete private pet files" on storage.objects;
create policy "owners delete private pet files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_user_is_primary_pet_owner(
    public.pet_id_from_storage_path(name)
  )
);

create or replace function public.sync_medication_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  recipient_id uuid;
  pet_name text;
begin
  update public.notifications
  set status = 'archived'
  where type = 'medication_reminder'
    and data->>'medication_id' = new.id::text
    and status <> 'archived';

  if new.reminder_enabled is not true or new.next_dose_date is null then
    return new;
  end if;

  select pet.owner_id, pet.name
    into recipient_id, pet_name
  from public.pets pet
  where pet.id = new.pet_id;

  if recipient_id is null then
    return new;
  end if;

  insert into public.notifications (
    user_id, pet_id, type, title, body, status, data
  ) values (
    recipient_id,
    new.pet_id,
    'medication_reminder',
    'Нагадування про препарат',
    coalesce(pet_name, 'Тварина') || ': ' || new.name ||
      ' — ' || to_char(new.next_dose_date, 'DD.MM.YYYY'),
    'unread',
    jsonb_build_object(
      'medication_id', new.id,
      'pet_name', pet_name,
      'next_dose_date', new.next_dose_date
    )
  );

  return new;
end;
$$;

drop trigger if exists sync_medication_notification
  on public.pet_medications;
create trigger sync_medication_notification
after insert or update of name, next_dose_date, reminder_enabled
on public.pet_medications
for each row execute function public.sync_medication_notification();

-- Remove only reminders that were delivered to someone other than the current
-- primary owner. Correctly addressed reminders remain untouched.
delete from public.notifications notification
using public.pet_medications medication, public.pets pet
where notification.type = 'medication_reminder'
  and notification.data->>'medication_id' = medication.id::text
  and medication.pet_id = pet.id
  and (
    pet.owner_id is null
    or notification.user_id <> pet.owner_id
  );

notify pgrst, 'reload schema';
