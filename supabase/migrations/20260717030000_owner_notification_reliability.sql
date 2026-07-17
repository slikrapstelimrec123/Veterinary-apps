-- Durable owner notifications for the simplified production notification
-- schema. Local iOS/Android scheduling is handled by the mobile app.

alter table public.notifications
  add column if not exists pet_id uuid references public.pets(id)
    on delete set null,
  add column if not exists data jsonb not null default '{}'::jsonb,
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
set search_path = public, pg_temp
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

  select pet.name into pet_name
  from public.pets pet
  where pet.id = new.pet_id;

  for recipient_id in
    select owner_id
    from (
      select pet.owner_id
      from public.pets pet
      where pet.id = new.pet_id and pet.owner_id is not null
      union
      select ownership.user_id
      from public.pet_owners ownership
      where ownership.pet_id = new.pet_id
    ) owners(owner_id)
  loop
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

create or replace function public.sync_owner_visit_notification()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  pet_name text;
begin
  update public.notifications
  set status = 'archived'
  where type = 'next_visit_recommended'
    and data->>'visit_record_id' = new.id::text
    and status <> 'archived';

  if new.status <> 'self_reported'
     or new.next_visit_recommended is not true
     or new.next_visit_date is null
     or new.owner_id is null then
    return new;
  end if;

  select pet.name into pet_name
  from public.pets pet
  where pet.id = new.pet_id;

  insert into public.notifications (
    user_id, pet_id, type, title, body, status, data
  ) values (
    new.owner_id,
    new.pet_id,
    'next_visit_recommended',
    'Запланований повторний прийом',
    coalesce(pet_name, 'Тварина') || ': ' ||
      to_char(new.next_visit_date, 'DD.MM.YYYY'),
    'unread',
    jsonb_build_object(
      'visit_record_id', new.id,
      'pet_name', pet_name,
      'next_visit_date', new.next_visit_date
    )
  );

  return new;
end;
$$;

drop trigger if exists sync_owner_visit_notification
  on public.visit_records;
create trigger sync_owner_visit_notification
after insert or update of next_visit_recommended, next_visit_date, status
on public.visit_records
for each row execute function public.sync_owner_visit_notification();

create or replace function public.notify_pet_transfer_recipient()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  pet_name text;
begin
  if new.to_user_id is null then
    return new;
  end if;

  select pet.name into pet_name
  from public.pets pet
  where pet.id = new.pet_id;

  insert into public.notifications (
    user_id, pet_id, type, title, body, status, data
  ) values (
    new.to_user_id,
    new.pet_id,
    'pet_transfer_request',
    'Запит на передачу тварини',
    coalesce(pet_name, 'Тварину') ||
      ' пропонують передати до вашого акаунта.',
    'unread',
    jsonb_build_object('transfer_id', new.id, 'pet_name', pet_name)
  );
  return new;
end;
$$;

drop trigger if exists notify_pet_transfer_recipient
  on public.pet_transfers;
create trigger notify_pet_transfer_recipient
after insert on public.pet_transfers
for each row execute function public.notify_pet_transfer_recipient();

-- Backfill existing reminders without touching medical rows.
do $$
declare
  medication_record record;
  visit_record record;
  recipient_id uuid;
  pet_name text;
begin
  for medication_record in
    select medication.*
    from public.pet_medications medication
    where medication.reminder_enabled is true
      and medication.next_dose_date is not null
  loop
    select pet.name into pet_name
    from public.pets pet
    where pet.id = medication_record.pet_id;

    for recipient_id in
      select owner_id
      from (
        select pet.owner_id
        from public.pets pet
        where pet.id = medication_record.pet_id
          and pet.owner_id is not null
        union
        select ownership.user_id
        from public.pet_owners ownership
        where ownership.pet_id = medication_record.pet_id
      ) owners(owner_id)
    loop
      if not exists (
        select 1
        from public.notifications notification
        where notification.user_id = recipient_id
          and notification.type = 'medication_reminder'
          and notification.data->>'medication_id' =
            medication_record.id::text
          and notification.status <> 'archived'
      ) then
        insert into public.notifications (
          user_id, pet_id, type, title, body, status, data
        ) values (
          recipient_id,
          medication_record.pet_id,
          'medication_reminder',
          'Нагадування про препарат',
          coalesce(pet_name, 'Тварина') || ': ' ||
            medication_record.name || ' — ' ||
            to_char(medication_record.next_dose_date, 'DD.MM.YYYY'),
          'unread',
          jsonb_build_object(
            'medication_id', medication_record.id,
            'pet_name', pet_name,
            'next_dose_date', medication_record.next_dose_date
          )
        );
      end if;
    end loop;
  end loop;

  for visit_record in
    select visit.*
    from public.visit_records visit
    where visit.status = 'self_reported'
      and visit.next_visit_recommended is true
      and visit.next_visit_date is not null
      and visit.owner_id is not null
  loop
    if not exists (
      select 1
      from public.notifications notification
      where notification.user_id = visit_record.owner_id
        and notification.type = 'next_visit_recommended'
        and notification.data->>'visit_record_id' =
          visit_record.id::text
        and notification.status <> 'archived'
    ) then
      select pet.name into pet_name
      from public.pets pet
      where pet.id = visit_record.pet_id;

      insert into public.notifications (
        user_id, pet_id, type, title, body, status, data
      ) values (
        visit_record.owner_id,
        visit_record.pet_id,
        'next_visit_recommended',
        'Запланований повторний прийом',
        coalesce(pet_name, 'Тварина') || ': ' ||
          to_char(visit_record.next_visit_date, 'DD.MM.YYYY'),
        'unread',
        jsonb_build_object(
          'visit_record_id', visit_record.id,
          'pet_name', pet_name,
          'next_visit_date', visit_record.next_visit_date
        )
      );
    end if;
  end loop;
end;
$$;

-- Keep retries idempotent if an earlier deployment stopped after backfilling.
delete from public.notifications notification
where notification.id in (
  select duplicate.id
  from (
    select
      id,
      row_number() over (
        partition by
          user_id,
          type,
          coalesce(data->>'medication_id', ''),
          coalesce(data->>'visit_record_id', ''),
          coalesce(data->>'transfer_id', '')
        order by created_at desc, id desc
      ) as duplicate_number
    from public.notifications
    where type in (
      'medication_reminder',
      'next_visit_recommended',
      'pet_transfer_request'
    )
      and status <> 'archived'
  ) duplicate
  where duplicate.duplicate_number > 1
);

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
