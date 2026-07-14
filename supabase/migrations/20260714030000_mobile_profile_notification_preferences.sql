create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  in_app_enabled boolean not null default true,
  email_enabled boolean not null default false,
  push_enabled boolean not null default false,
  sms_enabled boolean not null default false,
  appointment_reminders_enabled boolean not null default true,
  treatment_updates_enabled boolean not null default true,
  review_requests_enabled boolean not null default true,
  marketing_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences
  add column if not exists in_app_enabled boolean not null default true,
  add column if not exists email_enabled boolean not null default false,
  add column if not exists push_enabled boolean not null default false,
  add column if not exists sms_enabled boolean not null default false,
  add column if not exists appointment_reminders_enabled boolean not null default true,
  add column if not exists treatment_updates_enabled boolean not null default true,
  add column if not exists review_requests_enabled boolean not null default true,
  add column if not exists marketing_enabled boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists notification_preferences_user_idx
  on public.notification_preferences(user_id);

alter table public.notification_preferences enable row level security;

drop policy if exists "users read own notification preferences" on public.notification_preferences;
drop policy if exists "users insert own notification preferences" on public.notification_preferences;
drop policy if exists "users update own notification preferences" on public.notification_preferences;

create policy "users read own notification preferences"
on public.notification_preferences for select to authenticated
using (user_id = auth.uid());

create policy "users insert own notification preferences"
on public.notification_preferences for insert to authenticated
with check (user_id = auth.uid() and marketing_enabled = false);

create policy "users update own notification preferences"
on public.notification_preferences for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid() and marketing_enabled = false);

create or replace function public.get_my_notification_preferences()
returns public.notification_preferences
language plpgsql security definer set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  preferences public.notification_preferences;
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;

  insert into public.notification_preferences (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  select * into preferences
  from public.notification_preferences
  where user_id = current_user_id;
  return preferences;
end;
$$;

create or replace function public.save_my_notification_preferences(
  p_in_app_enabled boolean,
  p_appointment_reminders_enabled boolean,
  p_treatment_updates_enabled boolean,
  p_review_requests_enabled boolean
)
returns public.notification_preferences
language plpgsql security definer set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  preferences public.notification_preferences;
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;

  insert into public.notification_preferences (
    user_id, in_app_enabled, appointment_reminders_enabled,
    treatment_updates_enabled, review_requests_enabled,
    email_enabled, push_enabled, sms_enabled, marketing_enabled, updated_at
  ) values (
    current_user_id, p_in_app_enabled, p_appointment_reminders_enabled,
    p_treatment_updates_enabled, p_review_requests_enabled,
    false, false, false, false, now()
  )
  on conflict (user_id) do update set
    in_app_enabled = excluded.in_app_enabled,
    appointment_reminders_enabled = excluded.appointment_reminders_enabled,
    treatment_updates_enabled = excluded.treatment_updates_enabled,
    review_requests_enabled = excluded.review_requests_enabled,
    email_enabled = false,
    push_enabled = false,
    sms_enabled = false,
    marketing_enabled = false,
    updated_at = now()
  returning * into preferences;
  return preferences;
end;
$$;

revoke all on function public.get_my_notification_preferences() from public, anon;
revoke all on function public.save_my_notification_preferences(boolean, boolean, boolean, boolean) from public, anon;
grant execute on function public.get_my_notification_preferences() to authenticated;
grant execute on function public.save_my_notification_preferences(boolean, boolean, boolean, boolean) to authenticated;
