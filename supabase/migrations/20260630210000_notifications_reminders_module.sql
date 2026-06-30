-- In-app notifications, preferences, delivery placeholders, and scheduled reminders.
-- External email, SMS, and push providers are intentionally not connected in this stage.

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references profiles(id) on delete cascade,
  clinic_id uuid references clinics(id) on delete cascade,
  pet_id uuid references pets(id) on delete set null,
  appointment_id uuid references appointments(id) on delete set null,
  visit_record_id uuid references visit_records(id) on delete set null,
  document_id uuid references visit_documents(id) on delete set null,
  review_id uuid references reviews(id) on delete set null,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  status text not null default 'unread',
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notifications_status_check check (status in ('unread', 'read', 'archived')),
  constraint notifications_type_check check (
    type in (
      'appointment_created',
      'appointment_confirmed',
      'appointment_cancelled_by_clinic',
      'appointment_reminder_24h',
      'appointment_reminder_2h',
      'visit_record_published',
      'document_uploaded',
      'next_visit_recommended',
      'review_request',
      'clinic_message_placeholder',
      'new_appointment_request',
      'appointment_cancelled_by_owner',
      'appointment_upcoming_today',
      'visit_record_missing',
      'review_received',
      'subscription_limit_warning',
      'subscription_upgrade_request_status'
    )
  )
);

create table if not exists notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  in_app_enabled boolean not null default true,
  email_enabled boolean not null default false,
  push_enabled boolean not null default false,
  sms_enabled boolean not null default false,
  appointment_reminders_enabled boolean not null default true,
  treatment_updates_enabled boolean not null default true,
  review_requests_enabled boolean not null default true,
  new_appointment_alerts_enabled boolean not null default true,
  appointment_cancellation_alerts_enabled boolean not null default true,
  review_alerts_enabled boolean not null default true,
  subscription_limit_alerts_enabled boolean not null default true,
  marketing_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists notification_preferences_user_idx on notification_preferences(user_id);

create table if not exists notification_delivery_log (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references notifications(id) on delete cascade,
  channel text not null,
  status text not null default 'pending',
  provider text,
  provider_message_id text,
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notification_delivery_log_channel_check check (channel in ('in_app', 'email', 'push', 'sms')),
  constraint notification_delivery_log_status_check check (status in ('pending', 'sent', 'failed', 'skipped'))
);

create table if not exists scheduled_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references profiles(id) on delete cascade,
  clinic_id uuid references clinics(id) on delete cascade,
  appointment_id uuid references appointments(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  scheduled_for timestamptz not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint scheduled_notifications_status_check check (status in ('pending', 'sent', 'cancelled', 'failed'))
);

create index if not exists notifications_recipient_status_idx on notifications(recipient_user_id, status, created_at desc);
create index if not exists notifications_clinic_idx on notifications(clinic_id);
create index if not exists notifications_appointment_idx on notifications(appointment_id);
create index if not exists notification_delivery_log_notification_idx on notification_delivery_log(notification_id);
create index if not exists scheduled_notifications_recipient_idx on scheduled_notifications(recipient_user_id, status, scheduled_for);
create index if not exists scheduled_notifications_appointment_idx on scheduled_notifications(appointment_id, status);

alter table notifications enable row level security;
alter table notification_preferences enable row level security;
alter table notification_delivery_log enable row level security;
alter table scheduled_notifications enable row level security;

create or replace function public.get_notification_preferences(target_user_id uuid)
returns notification_preferences
language plpgsql
security definer
set search_path = public
as $$
declare
  prefs notification_preferences;
begin
  insert into notification_preferences (user_id)
  values (target_user_id)
  on conflict (user_id) do nothing;

  select *
  into prefs
  from notification_preferences
  where user_id = target_user_id;

  return prefs;
end;
$$;

create or replace function public.notification_allowed(target_user_id uuid, notification_type text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  prefs notification_preferences;
begin
  prefs := public.get_notification_preferences(target_user_id);

  if coalesce(prefs.in_app_enabled, true) is false then
    return false;
  end if;

  if notification_type in ('appointment_reminder_24h', 'appointment_reminder_2h') then
    return coalesce(prefs.appointment_reminders_enabled, true);
  end if;

  if notification_type in ('visit_record_published', 'document_uploaded', 'next_visit_recommended') then
    return coalesce(prefs.treatment_updates_enabled, true);
  end if;

  if notification_type = 'review_request' then
    return coalesce(prefs.review_requests_enabled, true);
  end if;

  if notification_type = 'new_appointment_request' then
    return coalesce(prefs.new_appointment_alerts_enabled, true);
  end if;

  if notification_type = 'appointment_cancelled_by_owner' then
    return coalesce(prefs.appointment_cancellation_alerts_enabled, true);
  end if;

  if notification_type = 'review_received' then
    return coalesce(prefs.review_alerts_enabled, true);
  end if;

  if notification_type = 'subscription_limit_warning' then
    return coalesce(prefs.subscription_limit_alerts_enabled, true);
  end if;

  return true;
end;
$$;

create or replace function public.create_notification(
  target_recipient_user_id uuid,
  target_type text,
  target_title text,
  target_body text,
  target_clinic_id uuid default null,
  target_pet_id uuid default null,
  target_appointment_id uuid default null,
  target_visit_record_id uuid default null,
  target_document_id uuid default null,
  target_review_id uuid default null,
  target_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  created_id uuid;
begin
  if target_recipient_user_id is null then
    return null;
  end if;

  if not public.notification_allowed(target_recipient_user_id, target_type) then
    return null;
  end if;

  insert into notifications (
    recipient_user_id,
    clinic_id,
    pet_id,
    appointment_id,
    visit_record_id,
    document_id,
    review_id,
    type,
    title,
    body,
    data
  )
  values (
    target_recipient_user_id,
    target_clinic_id,
    target_pet_id,
    target_appointment_id,
    target_visit_record_id,
    target_document_id,
    target_review_id,
    target_type,
    target_title,
    target_body,
    coalesce(target_data, '{}'::jsonb)
  )
  returning id into created_id;

  insert into notification_delivery_log (notification_id, channel, status, provider)
  values (created_id, 'in_app', 'sent', 'internal');

  return created_id;
end;
$$;

create or replace function public.create_notifications_for_clinic_members(
  target_clinic_id uuid,
  allowed_roles text[],
  target_type text,
  target_title text,
  target_body text,
  target_appointment_id uuid default null,
  target_review_id uuid default null,
  target_data jsonb default '{}'::jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  member_record record;
  created_count integer := 0;
  notification_id uuid;
begin
  for member_record in
    select user_id
    from clinic_members
    where clinic_id = target_clinic_id
      and status = 'active'
      and role = any(allowed_roles)
  loop
    notification_id := public.create_notification(
      member_record.user_id,
      target_type,
      target_title,
      target_body,
      target_clinic_id,
      null,
      target_appointment_id,
      null,
      null,
      target_review_id,
      target_data
    );

    if notification_id is not null then
      created_count := created_count + 1;
    end if;
  end loop;

  return created_count;
end;
$$;

create or replace function public.notify_subscription_limit_warning(target_clinic_id uuid, limit_code text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.has_clinic_role(target_clinic_id, array['clinic_owner', 'clinic_manager', 'veterinarian']) and not public.is_platform_admin() then
    raise exception 'Not allowed';
  end if;

  return public.create_notifications_for_clinic_members(
    target_clinic_id,
    array['clinic_owner', 'clinic_manager'],
    'subscription_limit_warning',
    'Ліміт тарифу досягнуто',
    'Клініка досягла ліміту поточного тарифу для цієї дії.',
    null,
    null,
    jsonb_build_object('route', 'subscription', 'limit', limit_code)
  );
end;
$$;

create or replace function public.create_appointment_reminders(target_appointment_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_record appointments;
  starts_at timestamptz;
  created_count integer := 0;
begin
  select * into appointment_record from appointments where id = target_appointment_id;

  if appointment_record.id is null or appointment_record.status not in ('confirmed', 'pending') then
    return 0;
  end if;

  starts_at := (appointment_record.appointment_date::text || ' ' || appointment_record.start_time::text)::timestamp at time zone 'Europe/Kiev';

  delete from scheduled_notifications
  where appointment_id = target_appointment_id
    and status = 'pending'
    and type in ('appointment_reminder_24h', 'appointment_reminder_2h');

  if starts_at - interval '24 hours' > now() then
    insert into scheduled_notifications (recipient_user_id, clinic_id, appointment_id, type, title, body, scheduled_for)
    values (appointment_record.owner_id, appointment_record.clinic_id, appointment_record.id, 'appointment_reminder_24h', 'Нагадування про запис', 'Ваш запис відбудеться завтра.', starts_at - interval '24 hours');
    created_count := created_count + 1;
  end if;

  if starts_at - interval '2 hours' > now() then
    insert into scheduled_notifications (recipient_user_id, clinic_id, appointment_id, type, title, body, scheduled_for)
    values (appointment_record.owner_id, appointment_record.clinic_id, appointment_record.id, 'appointment_reminder_2h', 'Запис скоро', 'Ваш запис відбудеться за дві години.', starts_at - interval '2 hours');
    created_count := created_count + 1;
  end if;

  return created_count;
end;
$$;

create or replace function public.cancel_appointment_reminders(target_appointment_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed_count integer := 0;
begin
  update scheduled_notifications
  set status = 'cancelled',
      updated_at = now()
  where appointment_id = target_appointment_id
    and status = 'pending';

  get diagnostics changed_count = row_count;
  return changed_count;
end;
$$;

create or replace function public.mark_notification_read(target_notification_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update notifications
  set status = 'read',
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where id = target_notification_id
    and recipient_user_id = auth.uid();
$$;

create or replace function public.mark_all_notifications_read()
returns void
language sql
security definer
set search_path = public
as $$
  update notifications
  set status = 'read',
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where recipient_user_id = auth.uid()
    and status = 'unread';
$$;

create or replace function public.notify_appointment_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.create_notification(
    new.owner_id,
    'appointment_created',
    'Запит на запис створено',
    'Ваш запит на запис надіслано до клініки.',
    new.clinic_id,
    new.pet_id,
    new.id,
    null,
    null,
    null,
    jsonb_build_object('route', 'appointment')
  );

  perform public.create_notifications_for_clinic_members(
    new.clinic_id,
    array['clinic_owner', 'clinic_manager'],
    'new_appointment_request',
    'Новий запит на запис',
    'Власник тварини надіслав запит на прийом.',
    new.id,
    null,
    jsonb_build_object('route', 'appointment')
  );

  return new;
end;
$$;

create or replace function public.notify_appointment_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'confirmed' then
    perform public.create_notification(
      new.owner_id,
      'appointment_confirmed',
      'Запис підтверджено',
      'Клініка підтвердила ваш запис.',
      new.clinic_id,
      new.pet_id,
      new.id,
      null,
      null,
      null,
      jsonb_build_object('route', 'appointment')
    );
    perform public.create_appointment_reminders(new.id);
  end if;

  if new.status = 'cancelled_by_clinic' then
    perform public.create_notification(
      new.owner_id,
      'appointment_cancelled_by_clinic',
      'Запис скасовано',
      'Клініка скасувала ваш запис.',
      new.clinic_id,
      new.pet_id,
      new.id,
      null,
      null,
      null,
      jsonb_build_object('route', 'appointment')
    );
    perform public.cancel_appointment_reminders(new.id);
  end if;

  if new.status = 'cancelled_by_owner' then
    perform public.create_notifications_for_clinic_members(
      new.clinic_id,
      array['clinic_owner', 'clinic_manager'],
      'appointment_cancelled_by_owner',
      'Запис скасовано власником',
      'Власник тварини скасував запис.',
      new.id,
      null,
      jsonb_build_object('route', 'appointment')
    );
    perform public.cancel_appointment_reminders(new.id);
  end if;

  if new.status = 'completed' then
    perform public.create_notification(
      new.owner_id,
      'review_request',
      'Як пройшов візит?',
      'Залиште відгук, щоб допомогти іншим власникам тварин.',
      new.clinic_id,
      new.pet_id,
      new.id,
      null,
      null,
      null,
      jsonb_build_object('route', 'review')
    );
    perform public.cancel_appointment_reminders(new.id);
  end if;

  return new;
end;
$$;

create or replace function public.notify_visit_record_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'published' and (tg_op = 'INSERT' or old.status is distinct from 'published') then
    if new.owner_id is not null then
      perform public.create_notification(
        new.owner_id,
        'visit_record_published',
        'Додано запис лікування',
        'Клініка додала новий запис до медичної історії вашої тварини.',
        new.clinic_id,
        new.pet_id,
        new.appointment_id,
        new.id,
        null,
        null,
        jsonb_build_object('route', 'visit_record')
      );

      if coalesce(new.next_visit_recommended, false) then
        perform public.create_notification(
          new.owner_id,
          'next_visit_recommended',
          'Рекомендовано повторний візит',
          'Клініка рекомендувала повторний візит для вашої тварини.',
          new.clinic_id,
          new.pet_id,
          new.appointment_id,
          new.id,
          null,
          null,
          jsonb_build_object('route', 'visit_record')
        );
      end if;
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.notify_visible_document_uploaded()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  record_owner uuid;
  record_appointment uuid;
begin
  if coalesce(new.is_visible_to_owner, false) is false then
    return new;
  end if;

  select owner_id, appointment_id
  into record_owner, record_appointment
  from visit_records
  where id = new.visit_record_id;

  if record_owner is not null then
    perform public.create_notification(
      record_owner,
      'document_uploaded',
      'Новий медичний документ',
      'До історії лікування вашої тварини додано новий документ.',
      new.clinic_id,
      new.pet_id,
      record_appointment,
      new.visit_record_id,
      new.id,
      null,
      jsonb_build_object('route', 'visit_record')
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_review_received()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.create_notifications_for_clinic_members(
    new.clinic_id,
    array['clinic_owner', 'clinic_manager'],
    'review_received',
    'Новий відгук',
    'Власник тварини залишив відгук про клініку.',
    new.appointment_id,
    new.id,
    jsonb_build_object('route', 'review')
  );

  return new;
end;
$$;

create or replace function public.notify_subscription_request_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = old.status or new.status not in ('approved', 'rejected') then
    return new;
  end if;

  perform public.create_notification(
    new.requested_by,
    'subscription_upgrade_request_status',
    case when new.status = 'approved' then 'Тариф підтверджено' else 'Запит на тариф відхилено' end,
    case when new.status = 'approved' then 'Запит на зміну тарифу клініки підтверджено вручну.' else 'Платформений адміністратор відхилив запит на зміну тарифу.' end,
    new.clinic_id,
    null,
    null,
    null,
    null,
    null,
    jsonb_build_object('route', 'subscription')
  );

  return new;
end;
$$;

drop trigger if exists appointments_notify_insert on appointments;
create trigger appointments_notify_insert
after insert on appointments
for each row execute function public.notify_appointment_insert();

drop trigger if exists appointments_notify_status_change on appointments;
create trigger appointments_notify_status_change
after update of status on appointments
for each row execute function public.notify_appointment_status_change();

drop trigger if exists visit_records_notify_published on visit_records;
create trigger visit_records_notify_published
after insert or update of status on visit_records
for each row execute function public.notify_visit_record_published();

drop trigger if exists visit_documents_notify_visible_upload on visit_documents;
create trigger visit_documents_notify_visible_upload
after insert on visit_documents
for each row execute function public.notify_visible_document_uploaded();

drop trigger if exists reviews_notify_received on reviews;
create trigger reviews_notify_received
after insert on reviews
for each row execute function public.notify_review_received();

drop trigger if exists subscription_upgrade_requests_notify_status on subscription_upgrade_requests;
create trigger subscription_upgrade_requests_notify_status
after update of status on subscription_upgrade_requests
for each row execute function public.notify_subscription_request_status();

revoke execute on function public.create_notification(uuid, text, text, text, uuid, uuid, uuid, uuid, uuid, uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.create_notifications_for_clinic_members(uuid, text[], text, text, text, uuid, uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.create_appointment_reminders(uuid) from public, anon, authenticated;
revoke execute on function public.cancel_appointment_reminders(uuid) from public, anon, authenticated;
revoke execute on function public.notification_allowed(uuid, text) from public, anon, authenticated;

drop policy if exists "users read own notifications" on notifications;
drop policy if exists "users update own notification status" on notifications;
drop policy if exists "platform admins read notifications" on notifications;
drop policy if exists "users read own notification preferences" on notification_preferences;
drop policy if exists "users update own notification preferences" on notification_preferences;
drop policy if exists "users insert own notification preferences" on notification_preferences;
drop policy if exists "platform admins read notification preferences" on notification_preferences;
drop policy if exists "platform admins read delivery logs" on notification_delivery_log;
drop policy if exists "users read own scheduled notifications" on scheduled_notifications;
drop policy if exists "platform admins manage scheduled notifications" on scheduled_notifications;

create policy "users read own notifications"
on notifications for select
using (recipient_user_id = auth.uid() or public.is_platform_admin());

create policy "users update own notification status"
on notifications for update
using (recipient_user_id = auth.uid())
with check (recipient_user_id = auth.uid() and status in ('unread', 'read', 'archived'));

create policy "platform admins read notifications"
on notifications for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "users read own notification preferences"
on notification_preferences for select
using (user_id = auth.uid() or public.is_platform_admin());

create policy "users insert own notification preferences"
on notification_preferences for insert
with check (user_id = auth.uid());

create policy "users update own notification preferences"
on notification_preferences for update
using (user_id = auth.uid())
with check (user_id = auth.uid() and marketing_enabled = false);

create policy "platform admins read notification preferences"
on notification_preferences for select
using (public.is_platform_admin());

create policy "platform admins read delivery logs"
on notification_delivery_log for select
using (public.is_platform_admin());

create policy "users read own scheduled notifications"
on scheduled_notifications for select
using (recipient_user_id = auth.uid() or public.is_platform_admin());

create policy "platform admins manage scheduled notifications"
on scheduled_notifications for all
using (public.is_platform_admin())
with check (public.is_platform_admin());
