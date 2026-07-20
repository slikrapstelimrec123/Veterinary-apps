-- Platform administrators can use the owner mobile experience without product
-- limits. The bypass is resolved from the protected profile role on the server;
-- clients cannot grant it to themselves.

alter table public.announcements
  drop constraint if exists announcements_publication_source_check;

alter table public.announcements
  add constraint announcements_publication_source_check check (
    publication_source is null
    or publication_source in (
      'free_quota',
      'subscription_quota',
      'event_free',
      'paid_credit',
      'platform_curated',
      'admin_unlimited'
    )
  );

create or replace function public.get_my_owner_plan()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if public.is_platform_admin() then
    return jsonb_build_object(
      'code', 'pro_plus',
      'name', 'Адміністратор',
      'pet_limit', -1,
      'breeding_monthly_limit', -1,
      'sale_monthly_limit', -1,
      'currency', 'UAH',
      'status', 'active',
      'cancel_at_period_end', false,
      'intro_offer_used', false,
      'unlimited', true
    );
  end if;

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
    'intro_offer_used', selected.intro_offer_used,
    'unlimited', false
  )
  into result
  from selected_plan selected
  join public.owner_plan_catalog plan on plan.code = selected.plan_code;

  return result;
end;
$$;

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

  if exists (
    select 1
    from public.profiles profile
    where profile.id = new.owner_id
      and profile.role = 'platform_admin'
  ) then
    return new;
  end if;

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
      detail = jsonb_build_object('limit', allowed_pets)::text;
  end if;
  return new;
end;
$$;

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
  owner_is_admin boolean;
begin
  if new.owner_id is null then
    raise exception 'Authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(new.owner_id::text));
  new.published_at := coalesce(new.published_at, now());
  new.ranking_at := coalesce(new.ranking_at, new.published_at);
  new.publication_expires_at := new.published_at + interval '30 days';
  new.delete_after := new.published_at + interval '60 days';

  if new.publication_source = 'platform_curated' then
    if auth.uid() is not null then
      raise exception 'PLATFORM_CURATED_REQUIRES_PRIVILEGED_SESSION';
    end if;
    new.publication_tier := 'standard';
    new.promoted_until := null;
    new.bumps_remaining := 0;
    new.next_bump_at := null;
    return new;
  end if;

  select exists (
    select 1
    from public.profiles profile
    where profile.id = new.owner_id
      and profile.role = 'platform_admin'
  )
  into owner_is_admin;

  if owner_is_admin then
    new.publication_source := 'admin_unlimited';
    new.publication_tier := 'standard';
    new.promoted_until := null;
    new.bumps_remaining := 0;
    new.next_bump_at := null;
    return new;
  end if;

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
  if public.is_platform_admin() then
    return jsonb_build_object(
      'allowed', true,
      'free', true,
      'remaining', null,
      'requires_purchase', false,
      'plan', 'admin'
    );
  end if;

  if target_type = 'event' then
    return jsonb_build_object(
      'allowed', true, 'free', true, 'remaining', null,
      'requires_purchase', false, 'plan', plan_data->>'code'
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

revoke all on function public.get_my_owner_plan() from public, anon;
grant execute on function public.get_my_owner_plan() to authenticated;

revoke all on function public.get_my_publication_access(text)
  from public, anon;
grant execute on function public.get_my_publication_access(text)
  to authenticated;

notify pgrst, 'reload schema';
