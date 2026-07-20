-- Owner subscriptions, paid announcement entitlements, quotas, expiry, and a
-- privacy-conscious analytics API for the separate Lappo admin console.

create table if not exists public.owner_plan_catalog (
  code text primary key,
  name text not null,
  monthly_price_minor integer,
  yearly_price_minor integer,
  intro_monthly_price_minor integer,
  currency text not null default 'UAH',
  pet_limit integer not null,
  breeding_monthly_limit integer not null,
  sale_monthly_limit integer not null,
  active boolean not null default true,
  sort_order integer not null default 0,
  updated_at timestamptz not null default now(),
  constraint owner_plan_catalog_code_check
    check (code in ('free', 'pro', 'pro_plus')),
  constraint owner_plan_catalog_limits_check
    check (
      pet_limit > 0
      and breeding_monthly_limit >= 0
      and sale_monthly_limit >= 0
    )
);

insert into public.owner_plan_catalog (
  code, name, monthly_price_minor, yearly_price_minor,
  intro_monthly_price_minor, pet_limit, breeding_monthly_limit,
  sale_monthly_limit, sort_order
)
values
  ('free', 'Free', null, null, null, 2, 1, 1, 0),
  ('pro', 'Pro', 7900, 79900, 3900, 5, 3, 3, 10),
  ('pro_plus', 'Pro+', 49900, 499900, 24900, 20, 20, 20, 20)
on conflict (code) do update set
  name = excluded.name,
  monthly_price_minor = excluded.monthly_price_minor,
  yearly_price_minor = excluded.yearly_price_minor,
  intro_monthly_price_minor = excluded.intro_monthly_price_minor,
  pet_limit = excluded.pet_limit,
  breeding_monthly_limit = excluded.breeding_monthly_limit,
  sale_monthly_limit = excluded.sale_monthly_limit,
  sort_order = excluded.sort_order,
  updated_at = now();

create table if not exists public.owner_entitlements (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  plan_code text not null default 'free'
    references public.owner_plan_catalog(code),
  status text not null default 'active',
  billing_period text,
  provider text,
  product_id text,
  provider_customer_id text,
  provider_entitlement_id text,
  current_period_start timestamptz not null default now(),
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  intro_offer_used boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint owner_entitlements_status_check check (
    status in ('active', 'grace_period', 'past_due', 'cancelled', 'expired')
  ),
  constraint owner_entitlements_period_check check (
    billing_period is null or billing_period in ('monthly', 'yearly', 'manual')
  ),
  constraint owner_entitlements_provider_check check (
    provider is null or provider in ('apple', 'google', 'manual')
  )
);

create table if not exists public.owner_billing_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null,
  provider_transaction_id text not null,
  product_id text not null,
  purchase_kind text not null,
  status text not null,
  amount_minor integer,
  currency text,
  purchased_at timestamptz not null,
  verified_at timestamptz,
  expires_at timestamptz,
  environment text not null default 'production',
  created_at timestamptz not null default now(),
  unique (provider, provider_transaction_id),
  constraint owner_billing_provider_check
    check (provider in ('apple', 'google', 'manual')),
  constraint owner_billing_kind_check
    check (purchase_kind in ('subscription', 'listing')),
  constraint owner_billing_status_check
    check (status in ('pending', 'verified', 'refunded', 'revoked', 'failed'))
);

create table if not exists public.listing_product_catalog (
  tier text primary key,
  name text not null,
  price_minor integer not null,
  currency text not null default 'UAH',
  promoted_days integer not null default 0,
  included_bumps integer not null default 0,
  active boolean not null default true,
  constraint listing_product_catalog_tier_check
    check (tier in ('standard', 'top_7', 'top_15'))
);

insert into public.listing_product_catalog (
  tier, name, price_minor, promoted_days, included_bumps
)
values
  ('standard', 'Стандарт', 4000, 0, 0),
  ('top_7', 'ТОП 7', 8000, 7, 3),
  ('top_15', 'ТОП 15', 15000, 15, 5)
on conflict (tier) do update set
  name = excluded.name,
  price_minor = excluded.price_minor,
  promoted_days = excluded.promoted_days,
  included_bumps = excluded.included_bumps,
  active = true;

create table if not exists public.owner_listing_credits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  transaction_id uuid not null
    references public.owner_billing_transactions(id) on delete restrict,
  tier text not null,
  status text not null default 'available',
  announcement_id uuid references public.announcements(id) on delete set null,
  created_at timestamptz not null default now(),
  consumed_at timestamptz,
  constraint owner_listing_credits_tier_check
    check (tier in ('standard', 'top_7', 'top_15')),
  constraint owner_listing_credits_status_check
    check (status in ('available', 'consumed', 'refunded', 'expired'))
);

create unique index if not exists owner_listing_credits_transaction_unique
  on public.owner_listing_credits(transaction_id);

alter table public.announcements
  add column if not exists listing_credit_id uuid
    references public.owner_listing_credits(id) on delete set null,
  add column if not exists publication_source text,
  add column if not exists publication_tier text not null default 'standard',
  add column if not exists published_at timestamptz,
  add column if not exists publication_expires_at timestamptz,
  add column if not exists delete_after timestamptz,
  add column if not exists promoted_until timestamptz,
  add column if not exists bumps_remaining integer not null default 0,
  add column if not exists next_bump_at timestamptz,
  add column if not exists ranking_at timestamptz;

alter table public.announcements
  drop constraint if exists announcements_publication_source_check,
  drop constraint if exists announcements_publication_tier_check;

alter table public.announcements
  add constraint announcements_publication_source_check check (
    publication_source is null
    or publication_source in (
      'free_quota', 'subscription_quota', 'event_free', 'paid_credit'
    )
  ),
  add constraint announcements_publication_tier_check check (
    publication_tier in ('standard', 'top_7', 'top_15')
  );

update public.announcements
set
  publication_source = coalesce(
    publication_source,
    case when announcement_type = 'event' then 'event_free'
         else 'free_quota' end
  ),
  published_at = coalesce(published_at, created_at),
  publication_expires_at = coalesce(
    publication_expires_at,
    created_at + interval '30 days'
  ),
  delete_after = coalesce(delete_after, created_at + interval '60 days');

update public.announcements
set ranking_at = coalesce(ranking_at, created_at);

create table if not exists public.platform_analytics_events (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles(id) on delete set null,
  event_name text not null,
  city text,
  entity_type text,
  entity_id uuid,
  properties jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create table if not exists public.platform_admin_audit_log (
  id bigint generated always as identity primary key,
  admin_user_id uuid not null references public.profiles(id) on delete restrict,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists owner_entitlements_plan_status_idx
  on public.owner_entitlements(plan_code, status, current_period_end);
create index if not exists owner_billing_transactions_user_date_idx
  on public.owner_billing_transactions(user_id, purchased_at desc);
create index if not exists owner_listing_credits_available_idx
  on public.owner_listing_credits(user_id, tier, created_at)
  where status = 'available';
create index if not exists announcements_expiry_idx
  on public.announcements(publication_expires_at)
  where status = 'active';
create index if not exists announcements_delete_after_idx
  on public.announcements(delete_after);
create index if not exists announcements_public_ranking_idx
  on public.announcements(
    announcement_type, promoted_until desc, ranking_at desc
  )
  where status = 'active' and moderation_status = 'published';
create index if not exists platform_analytics_events_name_date_idx
  on public.platform_analytics_events(event_name, occurred_at desc);
create index if not exists platform_analytics_events_city_date_idx
  on public.platform_analytics_events(city, occurred_at desc);

alter table public.owner_plan_catalog enable row level security;
alter table public.owner_entitlements enable row level security;
alter table public.owner_billing_transactions enable row level security;
alter table public.listing_product_catalog enable row level security;
alter table public.owner_listing_credits enable row level security;
alter table public.platform_analytics_events enable row level security;
alter table public.platform_admin_audit_log enable row level security;

drop policy if exists "users read active owner plans"
  on public.owner_plan_catalog;
create policy "users read active owner plans"
on public.owner_plan_catalog for select to authenticated
using (active);

drop policy if exists "users read own entitlement"
  on public.owner_entitlements;
create policy "users read own entitlement"
on public.owner_entitlements for select to authenticated
using (user_id = auth.uid() or public.is_platform_admin());

drop policy if exists "users read own billing"
  on public.owner_billing_transactions;
create policy "users read own billing"
on public.owner_billing_transactions for select to authenticated
using (user_id = auth.uid() or public.is_platform_admin());

drop policy if exists "users read active listing products"
  on public.listing_product_catalog;
create policy "users read active listing products"
on public.listing_product_catalog for select to authenticated
using (active);

drop policy if exists "users read own listing credits"
  on public.owner_listing_credits;
create policy "users read own listing credits"
on public.owner_listing_credits for select to authenticated
using (user_id = auth.uid() or public.is_platform_admin());

drop policy if exists "admins read analytics events"
  on public.platform_analytics_events;
create policy "admins read analytics events"
on public.platform_analytics_events for select to authenticated
using (public.is_platform_admin());

drop policy if exists "admins read audit log"
  on public.platform_admin_audit_log;
create policy "admins read audit log"
on public.platform_admin_audit_log for select to authenticated
using (public.is_platform_admin());

revoke all on public.owner_plan_catalog from anon;
revoke all on public.owner_entitlements from anon;
revoke all on public.owner_billing_transactions from anon;
revoke all on public.listing_product_catalog from anon;
revoke all on public.owner_listing_credits from anon;
revoke all on public.platform_analytics_events from anon, authenticated;
revoke all on public.platform_admin_audit_log from anon, authenticated;
grant select on public.owner_plan_catalog to authenticated;
grant select on public.owner_entitlements to authenticated;
grant select on public.owner_billing_transactions to authenticated;
grant select on public.listing_product_catalog to authenticated;
grant select on public.owner_listing_credits to authenticated;

create or replace function public.get_my_owner_plan()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with active_entitlement as (
    select entitlement.*
    from public.owner_entitlements entitlement
    where entitlement.user_id = auth.uid()
      and entitlement.status in ('active', 'grace_period')
      and (
        entitlement.current_period_end is null
        or entitlement.current_period_end > now()
      )
    limit 1
  ),
  selected_plan as (
    select coalesce(entitlement.plan_code, 'free') as plan_code,
           entitlement.status,
           entitlement.billing_period,
           entitlement.current_period_start,
           entitlement.current_period_end,
           coalesce(entitlement.cancel_at_period_end, false)
             as cancel_at_period_end,
           coalesce(entitlement.intro_offer_used, false) as intro_offer_used
    from (select 1) seed
    left join active_entitlement entitlement on true
  )
  select jsonb_build_object(
    'code', plan.code,
    'name', plan.name,
    'pet_limit', plan.pet_limit,
    'breeding_monthly_limit', plan.breeding_monthly_limit,
    'sale_monthly_limit', plan.sale_monthly_limit,
    'monthly_price_minor', plan.monthly_price_minor,
    'yearly_price_minor', plan.yearly_price_minor,
    'intro_monthly_price_minor', plan.intro_monthly_price_minor,
    'currency', plan.currency,
    'status', coalesce(selected.status, 'active'),
    'billing_period', selected.billing_period,
    'current_period_start', selected.current_period_start,
    'current_period_end', selected.current_period_end,
    'cancel_at_period_end', selected.cancel_at_period_end,
    'intro_offer_used', selected.intro_offer_used
  )
  from selected_plan selected
  join public.owner_plan_catalog plan on plan.code = selected.plan_code;
$$;

revoke all on function public.get_my_owner_plan() from public, anon;
grant execute on function public.get_my_owner_plan() to authenticated;

create or replace function public.assert_owner_pet_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed_pets integer;
  current_pets integer;
begin
  if new.owner_id is null then
    return new;
  end if;

  -- Always resolve the limit for the actual owner. This also protects
  -- ownership transfers and service-role maintenance jobs.
  select coalesce(plan.pet_limit, 2)
  into allowed_pets
  from (select 1) seed
  left join public.owner_entitlements entitlement
    on entitlement.user_id = new.owner_id
    and entitlement.status in ('active', 'grace_period')
    and (
      entitlement.current_period_end is null
      or entitlement.current_period_end > now()
    )
  left join public.owner_plan_catalog plan
    on plan.code = coalesce(entitlement.plan_code, 'free')
  limit 1;

  select count(*)
  into current_pets
  from public.pets pet
  where pet.owner_id = new.owner_id
    and (tg_op = 'INSERT' or pet.id <> new.id);

  if current_pets >= allowed_pets then
    raise exception using
      errcode = 'P0001',
      message = 'PET_PLAN_LIMIT_REACHED',
      detail = jsonb_build_object(
        'limit', allowed_pets
      )::text;
  end if;
  return new;
end;
$$;

drop trigger if exists pets_enforce_owner_plan_limit on public.pets;
create trigger pets_enforce_owner_plan_limit
before insert or update of owner_id on public.pets
for each row execute function public.assert_owner_pet_limit();

create or replace function public.reserve_announcement_publication()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  plan_data jsonb;
  plan_code text;
  period_start timestamptz;
  category_limit integer;
  used_count integer;
  credit public.owner_listing_credits;
begin
  if new.owner_id is null then
    raise exception 'Authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(new.owner_id::text));
  new.published_at := coalesce(new.published_at, now());
  new.ranking_at := coalesce(new.ranking_at, new.published_at);
  new.publication_expires_at := new.published_at + interval '30 days';
  new.delete_after := new.published_at + interval '60 days';

  if new.announcement_type = 'event' then
    new.publication_source := 'event_free';
    new.publication_tier := 'standard';
    return new;
  end if;

  if new.listing_credit_id is not null then
    select *
    into credit
    from public.owner_listing_credits
    where id = new.listing_credit_id
      and user_id = new.owner_id
      and status = 'available'
    for update;

    if credit.id is null then
      raise exception 'LISTING_CREDIT_REQUIRED';
    end if;

    new.publication_source := 'paid_credit';
    new.publication_tier := credit.tier;
    if credit.tier = 'top_7' then
      new.promoted_until := new.published_at + interval '7 days';
      new.bumps_remaining := 3;
      new.next_bump_at := new.published_at + interval '2 days';
    elsif credit.tier = 'top_15' then
      new.promoted_until := new.published_at + interval '15 days';
      new.bumps_remaining := 5;
      new.next_bump_at := new.published_at + interval '3 days';
    end if;
    return new;
  end if;

  if new.announcement_type in ('service', 'offer') then
    raise exception 'LISTING_CREDIT_REQUIRED';
  end if;

  select public.get_my_owner_plan() into plan_data;
  plan_code := coalesce(plan_data->>'code', 'free');
  period_start := date_trunc('month', now());

  if plan_code = 'free' then
    select count(*)
    into used_count
    from public.announcements announcement
    where announcement.owner_id = new.owner_id
      and announcement.announcement_type in ('sale', 'breeding')
      and announcement.created_at >= period_start;
    category_limit := 1;
  else
    category_limit := case
      when new.announcement_type = 'sale'
        then (plan_data->>'sale_monthly_limit')::integer
      else (plan_data->>'breeding_monthly_limit')::integer
    end;
    select count(*)
    into used_count
    from public.announcements announcement
    where announcement.owner_id = new.owner_id
      and announcement.announcement_type = new.announcement_type
      and announcement.created_at >= period_start;
  end if;

  if used_count >= category_limit then
    raise exception using
      errcode = 'P0001',
      message = 'ANNOUNCEMENT_PLAN_LIMIT_REACHED',
      detail = jsonb_build_object(
        'limit', category_limit,
        'used', used_count,
        'plan', plan_code,
        'type', new.announcement_type
      )::text;
  end if;

  new.publication_source := case
    when plan_code = 'free' then 'free_quota'
    else 'subscription_quota'
  end;
  new.publication_tier := 'standard';
  return new;
end;
$$;

create or replace function public.consume_announcement_credit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.listing_credit_id is not null then
    update public.owner_listing_credits
    set
      status = 'consumed',
      announcement_id = new.id,
      consumed_at = now()
    where id = new.listing_credit_id
      and user_id = new.owner_id
      and status = 'available';
  end if;
  return new;
end;
$$;

drop trigger if exists announcements_reserve_publication
  on public.announcements;
create trigger announcements_reserve_publication
before insert on public.announcements
for each row execute function public.reserve_announcement_publication();

drop trigger if exists announcements_consume_credit
  on public.announcements;
create trigger announcements_consume_credit
after insert on public.announcements
for each row execute function public.consume_announcement_credit();

create or replace function public.get_my_publication_access(
  target_type text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  plan_data jsonb := public.get_my_owner_plan();
  plan_code text;
  category_limit integer;
  used_count integer;
  period_start timestamptz := date_trunc('month', now());
begin
  if target_type = 'event' then
    return jsonb_build_object(
      'allowed', true, 'free', true, 'remaining', null,
      'plan', plan_data->>'code'
    );
  end if;
  if target_type in ('service', 'offer') then
    return jsonb_build_object(
      'allowed', false, 'free', false, 'remaining', 0,
      'requires_purchase', true, 'plan', plan_data->>'code'
    );
  end if;

  plan_code := coalesce(plan_data->>'code', 'free');
  if plan_code = 'free' then
    category_limit := 1;
    select count(*) into used_count
    from public.announcements
    where owner_id = auth.uid()
      and announcement_type in ('sale', 'breeding')
      and created_at >= period_start;
  else
    category_limit := case
      when target_type = 'sale'
        then (plan_data->>'sale_monthly_limit')::integer
      else (plan_data->>'breeding_monthly_limit')::integer
    end;
    select count(*) into used_count
    from public.announcements
    where owner_id = auth.uid()
      and announcement_type = target_type
      and created_at >= period_start;
  end if;

  return jsonb_build_object(
    'allowed', used_count < category_limit,
    'free', used_count < category_limit,
    'remaining', greatest(category_limit - used_count, 0),
    'requires_purchase', used_count >= category_limit,
    'plan', plan_code
  );
end;
$$;

revoke all on function public.get_my_publication_access(text)
  from public, anon;
grant execute on function public.get_my_publication_access(text)
  to authenticated;

create or replace function public.expire_and_cleanup_announcements()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  expired_count integer;
  deleted_count integer;
begin
  update public.announcements
  set
    ranking_at = now(),
    bumps_remaining = bumps_remaining - 1,
    next_bump_at = case
      when bumps_remaining - 1 <= 0 then null
      when publication_tier = 'top_7' then now() + interval '2 days'
      else now() + interval '3 days'
    end,
    updated_at = now()
  where status = 'active'
    and bumps_remaining > 0
    and next_bump_at is not null
    and next_bump_at <= now()
    and promoted_until > now();

  update public.announcements
  set
    promoted_until = null,
    ranking_at = published_at,
    bumps_remaining = 0,
    next_bump_at = null,
    updated_at = now()
  where promoted_until is not null
    and promoted_until <= now();

  update public.announcements
  set status = 'inactive', updated_at = now()
  where status = 'active'
    and publication_expires_at <= now();
  get diagnostics expired_count = row_count;

  delete from public.announcements
  where delete_after <= now();
  get diagnostics deleted_count = row_count;

  return jsonb_build_object(
    'expired', expired_count,
    'deleted', deleted_count
  );
end;
$$;

revoke all on function public.expire_and_cleanup_announcements()
  from public, anon, authenticated;

do $$
begin
  if exists (
    select 1 from pg_extension where extname = 'pg_cron'
  ) then
    begin
      execute $cron$
        select cron.unschedule(jobid)
        from cron.job
        where jobname = 'lappo-announcement-lifecycle'
      $cron$;
    exception when others then
      null;
    end;
    execute $cron$
      select cron.schedule(
        'lappo-announcement-lifecycle',
        '17 * * * *',
        'select public.expire_and_cleanup_announcements();'
      )
    $cron$;
  end if;
end
$$;

create or replace function public.track_platform_event(
  target_event_name text,
  target_entity_type text default null,
  target_entity_id uuid default null,
  target_properties jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  profile_city text;
begin
  if auth.uid() is null
     or target_event_name not in (
       'onboarding_completed', 'pet_created', 'announcement_created',
       'paywall_viewed', 'purchase_started', 'purchase_completed',
       'subscription_started', 'subscription_renewed',
       'subscription_cancelled'
     ) then
    return;
  end if;
  select profile.city into profile_city
  from public.profiles profile
  where profile.id = auth.uid();
  insert into public.platform_analytics_events (
    user_id, event_name, city, entity_type, entity_id, properties
  )
  values (
    auth.uid(), target_event_name, profile_city,
    target_entity_type, target_entity_id,
    coalesce(target_properties, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.track_platform_event(text, text, uuid, jsonb)
  from public, anon;
grant execute on function public.track_platform_event(text, text, uuid, jsonb)
  to authenticated;

create or replace function public.admin_dashboard_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  return jsonb_build_object(
    'users_total', (select count(*) from public.profiles),
    'users_30d', (
      select count(*) from public.profiles
      where created_at >= now() - interval '30 days'
    ),
    'pets_total', (select count(*) from public.pets),
    'announcements_active', (
      select count(*) from public.announcements where status = 'active'
    ),
    'announcements_paid', (
      select count(*) from public.announcements
      where publication_source = 'paid_credit'
    ),
    'pro_active', (
      select count(*) from public.owner_entitlements
      where plan_code = 'pro'
        and status in ('active', 'grace_period')
        and (current_period_end is null or current_period_end > now())
    ),
    'pro_plus_active', (
      select count(*) from public.owner_entitlements
      where plan_code = 'pro_plus'
        and status in ('active', 'grace_period')
        and (current_period_end is null or current_period_end > now())
    ),
    'verified_revenue_minor', (
      select coalesce(sum(amount_minor), 0)
      from public.owner_billing_transactions
      where status = 'verified'
    ),
    'currency', 'UAH'
  );
end;
$$;

create or replace function public.admin_city_analytics()
returns table (
  city text,
  users_count bigint,
  pets_count bigint,
  announcements_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  return query
  with cities as (
    select coalesce(nullif(trim(profile.city), ''), 'Не вказано') as city,
           count(*) as users_count
    from public.profiles profile
    group by 1
  ),
  pet_counts as (
    select coalesce(nullif(trim(profile.city), ''), 'Не вказано') as city,
           count(pet.id) as pets_count
    from public.profiles profile
    left join public.pets pet on pet.owner_id = profile.id
    group by 1
  ),
  announcement_counts as (
    select coalesce(nullif(trim(announcement.city), ''), 'Не вказано') as city,
           count(*) as announcements_count
    from public.announcements announcement
    group by 1
  )
  select cities.city, cities.users_count,
         coalesce(pet_counts.pets_count, 0),
         coalesce(announcement_counts.announcements_count, 0)
  from cities
  left join pet_counts using (city)
  left join announcement_counts using (city)
  order by cities.users_count desc;
end;
$$;

create or replace function public.admin_plan_analytics()
returns table (
  plan_code text,
  active_subscriptions bigint,
  monthly_subscriptions bigint,
  yearly_subscriptions bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  return query
  select plan.code,
         count(entitlement.user_id) filter (
           where entitlement.status in ('active', 'grace_period')
             and (
               entitlement.current_period_end is null
               or entitlement.current_period_end > now()
             )
         ),
         count(entitlement.user_id) filter (
           where entitlement.billing_period = 'monthly'
             and entitlement.status in ('active', 'grace_period')
         ),
         count(entitlement.user_id) filter (
           where entitlement.billing_period = 'yearly'
             and entitlement.status in ('active', 'grace_period')
         )
  from public.owner_plan_catalog plan
  left join public.owner_entitlements entitlement
    on entitlement.plan_code = plan.code
  group by plan.code, plan.sort_order
  order by plan.sort_order;
end;
$$;

revoke all on function public.admin_dashboard_overview()
  from public, anon;
revoke all on function public.admin_city_analytics()
  from public, anon;
revoke all on function public.admin_plan_analytics()
  from public, anon;
grant execute on function public.admin_dashboard_overview()
  to authenticated;
grant execute on function public.admin_city_analytics()
  to authenticated;
grant execute on function public.admin_plan_analytics()
  to authenticated;

notify pgrst, 'reload schema';
