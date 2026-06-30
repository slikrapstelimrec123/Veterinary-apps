-- Clinic subscription plans, usage limits, and mock upgrade requests.
-- No real payment provider is connected in this stage.

create table if not exists subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  price_monthly numeric,
  price_yearly numeric,
  currency text not null default 'USD',
  is_active boolean not null default true,
  is_public boolean not null default true,
  sort_order integer not null default 0,
  limits jsonb not null default '{}'::jsonb,
  features jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists clinic_subscriptions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  plan_id uuid not null references subscription_plans(id),
  status text not null default 'active',
  billing_period text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  trial_ends_at timestamptz,
  cancel_at_period_end boolean not null default false,
  external_provider text,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clinic_subscriptions_status_check check (status in ('trialing', 'active', 'past_due', 'cancelled', 'expired', 'suspended', 'manual')),
  constraint clinic_subscriptions_billing_period_check check (billing_period is null or billing_period in ('monthly', 'yearly', 'manual'))
);

create unique index if not exists clinic_subscriptions_one_current_idx
on clinic_subscriptions(clinic_id)
where status in ('trialing', 'active', 'manual', 'past_due');

create table if not exists subscription_usage (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  period_start timestamptz not null,
  period_end timestamptz not null,
  doctors_count integer not null default 0,
  services_count integer not null default 0,
  appointments_count integer not null default 0,
  visit_records_count integer not null default 0,
  documents_count integer not null default 0,
  storage_used_mb numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists subscription_usage_clinic_period_idx
on subscription_usage(clinic_id, period_start, period_end);

create table if not exists subscription_upgrade_requests (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  requested_plan_id uuid not null references subscription_plans(id),
  requested_by uuid not null references profiles(id),
  status text not null default 'pending',
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_upgrade_requests_status_check check (status in ('pending', 'approved', 'rejected', 'cancelled'))
);

create index if not exists clinic_subscriptions_clinic_idx on clinic_subscriptions(clinic_id);
create index if not exists clinic_subscriptions_plan_idx on clinic_subscriptions(plan_id);
create index if not exists subscription_usage_clinic_idx on subscription_usage(clinic_id);
create index if not exists subscription_upgrade_requests_clinic_idx on subscription_upgrade_requests(clinic_id);
create index if not exists subscription_upgrade_requests_status_idx on subscription_upgrade_requests(status);

insert into subscription_plans (code, name, description, price_monthly, price_yearly, currency, sort_order, limits, features)
values
  (
    'free',
    'Free',
    'Стартовий план для невеликої клініки, щоб перевірити базовий робочий процес.',
    0,
    0,
    'USD',
    10,
    '{
      "max_doctors": 2,
      "max_services": 10,
      "max_clinic_managers": 1,
      "max_appointments_per_month": 50,
      "max_visit_records": 50,
      "max_documents": 50,
      "max_storage_mb": 512,
      "can_publish_clinic_profile": true,
      "can_use_reviews": true,
      "can_use_advanced_analytics": false,
      "can_export_data": false,
      "can_use_multi_location": false,
      "can_use_priority_support": false
    }'::jsonb,
    '["Базовий профіль клініки", "До 2 лікарів", "Базові відгуки"]'::jsonb
  ),
  (
    'basic',
    'Basic',
    'План для клініки, що активно приймає онлайн-записи.',
    29,
    290,
    'USD',
    20,
    '{
      "max_doctors": 5,
      "max_services": 30,
      "max_clinic_managers": 2,
      "max_appointments_per_month": 300,
      "max_visit_records": 1000,
      "max_documents": 1000,
      "max_storage_mb": 5120,
      "can_publish_clinic_profile": true,
      "can_use_reviews": true,
      "can_use_advanced_analytics": false,
      "can_export_data": false,
      "can_use_multi_location": false,
      "can_use_priority_support": false
    }'::jsonb,
    '["Публічний профіль", "Відгуки та рейтинги", "Базова підтримка"]'::jsonb
  ),
  (
    'pro',
    'Pro',
    'Розширений план для команди з більшим потоком записів і документів.',
    79,
    790,
    'USD',
    30,
    '{
      "max_doctors": 20,
      "max_services": 200,
      "max_clinic_managers": 10,
      "max_appointments_per_month": 2000,
      "max_visit_records": 20000,
      "max_documents": 20000,
      "max_storage_mb": 51200,
      "can_publish_clinic_profile": true,
      "can_use_reviews": true,
      "can_use_advanced_analytics": true,
      "can_export_data": true,
      "can_use_multi_location": false,
      "can_use_priority_support": true
    }'::jsonb,
    '["Розширені ліміти", "Аналітика placeholder", "Пріоритетна підтримка placeholder"]'::jsonb
  ),
  (
    'enterprise',
    'Enterprise',
    'Індивідуальний план для мереж і великих клінік з ручною активацією.',
    null,
    null,
    'USD',
    40,
    '{
      "max_doctors": -1,
      "max_services": -1,
      "max_clinic_managers": -1,
      "max_appointments_per_month": -1,
      "max_visit_records": -1,
      "max_documents": -1,
      "max_storage_mb": -1,
      "can_publish_clinic_profile": true,
      "can_use_reviews": true,
      "can_use_advanced_analytics": true,
      "can_export_data": true,
      "can_use_multi_location": true,
      "can_use_priority_support": true
    }'::jsonb,
    '["Індивідуальні ліміти", "Multi-location placeholder", "Ручна активація"]'::jsonb
  )
on conflict (code) do update
set name = excluded.name,
    description = excluded.description,
    price_monthly = excluded.price_monthly,
    price_yearly = excluded.price_yearly,
    currency = excluded.currency,
    sort_order = excluded.sort_order,
    limits = excluded.limits,
    features = excluded.features,
    is_active = true,
    is_public = true,
    updated_at = now();

insert into clinic_subscriptions (clinic_id, plan_id, status, billing_period, current_period_start)
select clinics.id, subscription_plans.id, 'active', 'manual', now()
from clinics
join subscription_plans on subscription_plans.code = 'free'
where not exists (
  select 1
  from clinic_subscriptions existing
  where existing.clinic_id = clinics.id
    and existing.status in ('trialing', 'active', 'manual', 'past_due')
);

alter table subscription_plans enable row level security;
alter table clinic_subscriptions enable row level security;
alter table subscription_usage enable row level security;
alter table subscription_upgrade_requests enable row level security;

create or replace function public.get_clinic_active_subscription(target_clinic_id uuid)
returns table (
  subscription_id uuid,
  plan_id uuid,
  plan_code text,
  plan_name text,
  status text,
  billing_period text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  trial_ends_at timestamptz,
  cancel_at_period_end boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    clinic_subscriptions.id,
    subscription_plans.id,
    subscription_plans.code,
    subscription_plans.name,
    clinic_subscriptions.status,
    clinic_subscriptions.billing_period,
    clinic_subscriptions.current_period_start,
    clinic_subscriptions.current_period_end,
    clinic_subscriptions.trial_ends_at,
    clinic_subscriptions.cancel_at_period_end
  from clinic_subscriptions
  join subscription_plans on subscription_plans.id = clinic_subscriptions.plan_id
  where clinic_subscriptions.clinic_id = target_clinic_id
    and clinic_subscriptions.status in ('trialing', 'active', 'manual', 'past_due')
  order by clinic_subscriptions.created_at desc
  limit 1;
$$;

create or replace function public.get_clinic_plan_limits(target_clinic_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select subscription_plans.limits
      from clinic_subscriptions
      join subscription_plans on subscription_plans.id = clinic_subscriptions.plan_id
      where clinic_subscriptions.clinic_id = target_clinic_id
        and clinic_subscriptions.status in ('trialing', 'active', 'manual', 'past_due')
      order by clinic_subscriptions.created_at desc
      limit 1
    ),
    (
      select limits
      from subscription_plans
      where code = 'free'
      limit 1
    ),
    '{}'::jsonb
  );
$$;

create or replace function public.get_clinic_usage(target_clinic_id uuid)
returns table (
  doctors_count integer,
  services_count integer,
  appointments_count integer,
  visit_records_count integer,
  documents_count integer,
  storage_used_mb numeric,
  period_start timestamptz,
  period_end timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with period as (
    select date_trunc('month', now()) as starts_at, date_trunc('month', now()) + interval '1 month' as ends_at
  )
  select
    (select count(*)::integer from doctors where clinic_id = target_clinic_id and status <> 'archived'),
    (select count(*)::integer from services where clinic_id = target_clinic_id and status <> 'archived'),
    (select count(*)::integer from appointments, period where clinic_id = target_clinic_id and appointment_date >= period.starts_at::date and appointment_date < period.ends_at::date),
    (select count(*)::integer from visit_records where clinic_id = target_clinic_id),
    (select count(*)::integer from visit_documents where clinic_id = target_clinic_id),
    coalesce((select round((sum(coalesce(file_size, file_size_bytes::integer, 0)) / 1048576.0)::numeric, 2) from visit_documents where clinic_id = target_clinic_id), 0),
    (select starts_at from period),
    (select ends_at from period);
$$;

create or replace function public.limit_allows(current_value numeric, max_value numeric)
returns boolean
language sql
immutable
as $$
  select max_value < 0 or current_value < max_value;
$$;

create or replace function public.can_clinic_add_doctor(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with limits as (select public.get_clinic_plan_limits(target_clinic_id) as data)
  select public.limit_allows(usage.doctors_count, coalesce((limits.data->>'max_doctors')::numeric, 0))
  from public.get_clinic_usage(target_clinic_id) usage, limits;
$$;

create or replace function public.can_clinic_add_service(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with limits as (select public.get_clinic_plan_limits(target_clinic_id) as data)
  select public.limit_allows(usage.services_count, coalesce((limits.data->>'max_services')::numeric, 0))
  from public.get_clinic_usage(target_clinic_id) usage, limits;
$$;

create or replace function public.can_clinic_create_appointment(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with limits as (select public.get_clinic_plan_limits(target_clinic_id) as data)
  select public.limit_allows(usage.appointments_count, coalesce((limits.data->>'max_appointments_per_month')::numeric, 0))
  from public.get_clinic_usage(target_clinic_id) usage, limits;
$$;

create or replace function public.can_clinic_create_visit_record(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with limits as (select public.get_clinic_plan_limits(target_clinic_id) as data)
  select public.limit_allows(usage.visit_records_count, coalesce((limits.data->>'max_visit_records')::numeric, 0))
  from public.get_clinic_usage(target_clinic_id) usage, limits;
$$;

create or replace function public.can_clinic_upload_document(target_clinic_id uuid, file_size_bytes bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with limits as (select public.get_clinic_plan_limits(target_clinic_id) as data)
  select
    public.limit_allows(usage.documents_count, coalesce((limits.data->>'max_documents')::numeric, 0))
    and (
      coalesce((limits.data->>'max_storage_mb')::numeric, 0) < 0
      or usage.storage_used_mb + (coalesce(file_size_bytes, 0) / 1048576.0) <= coalesce((limits.data->>'max_storage_mb')::numeric, 0)
    )
  from public.get_clinic_usage(target_clinic_id) usage, limits;
$$;

create or replace function public.can_clinic_publish_profile(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((public.get_clinic_plan_limits(target_clinic_id)->>'can_publish_clinic_profile')::boolean, false);
$$;

create or replace function public.can_clinic_use_reviews(target_clinic_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((public.get_clinic_plan_limits(target_clinic_id)->>'can_use_reviews')::boolean, false);
$$;

drop policy if exists "public reads active public plans" on subscription_plans;
drop policy if exists "platform admins manage subscription plans" on subscription_plans;
drop policy if exists "clinic members read own clinic subscriptions" on clinic_subscriptions;
drop policy if exists "platform admins manage clinic subscriptions" on clinic_subscriptions;
drop policy if exists "clinic managers read own usage" on subscription_usage;
drop policy if exists "platform admins read all usage" on subscription_usage;
drop policy if exists "clinic owners create upgrade requests" on subscription_upgrade_requests;
drop policy if exists "clinic owners read own upgrade requests" on subscription_upgrade_requests;
drop policy if exists "platform admins manage upgrade requests" on subscription_upgrade_requests;

create policy "public reads active public plans"
on subscription_plans for select
using (is_active = true and is_public = true);

create policy "platform admins manage subscription plans"
on subscription_plans for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "clinic members read own clinic subscriptions"
on clinic_subscriptions for select
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

create policy "platform admins manage clinic subscriptions"
on clinic_subscriptions for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "clinic managers read own usage"
on subscription_usage for select
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

create policy "platform admins read all usage"
on subscription_usage for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "clinic owners create upgrade requests"
on subscription_upgrade_requests for insert
with check (
  requested_by = auth.uid()
  and public.has_clinic_role(clinic_id, array['clinic_owner'])
);

create policy "clinic owners read own upgrade requests"
on subscription_upgrade_requests for select
using (
  public.has_clinic_role(clinic_id, array['clinic_owner'])
  or public.is_platform_admin()
);

create policy "platform admins manage upgrade requests"
on subscription_upgrade_requests for update
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists "owners create pending own pet appointments" on appointments;
create policy "owners create pending own pet appointments"
on appointments for insert
with check (
  owner_id = auth.uid()
  and status = 'pending'
  and public.owns_pet(pet_id)
  and public.can_clinic_create_appointment(clinic_id)
  and exists (
    select 1
    from clinics
    where clinics.id = appointments.clinic_id
      and clinics.status = 'published'
      and clinics.published = true
  )
  and exists (
    select 1
    from services
    where services.id = appointments.service_id
      and services.clinic_id = appointments.clinic_id
      and services.status = 'active'
      and services.is_public = true
  )
  and (
    doctor_id is null
    or exists (
      select 1
      from doctors
      where doctors.id = appointments.doctor_id
        and doctors.clinic_id = appointments.clinic_id
        and doctors.status = 'active'
        and doctors.is_public = true
    )
  )
);
