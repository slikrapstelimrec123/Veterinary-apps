-- Secure, auditable account management for the private Lappo admin console.

create or replace function public.admin_user_analytics()
returns table (
  user_id uuid,
  email text,
  full_name text,
  phone text,
  city text,
  created_at timestamptz,
  pet_count bigint,
  visit_count bigint,
  document_count bigint,
  announcement_count bigint,
  active_announcement_count bigint,
  plan_code text,
  plan_status text,
  plan_end timestamptz,
  available_listing_credits bigint,
  is_banned boolean
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
  with pet_totals as (
    select pet.owner_id, count(*) as pet_count
    from public.pets pet
    group by pet.owner_id
  ),
  visit_totals as (
    select pet.owner_id, count(visit.id) as visit_count
    from public.pets pet
    join public.visit_records visit on visit.pet_id = pet.id
    group by pet.owner_id
  ),
  document_totals as (
    select pet.owner_id, count(document.id) as document_count
    from public.pets pet
    join public.visit_records visit on visit.pet_id = pet.id
    join public.visit_documents document on document.visit_id = visit.id
    group by pet.owner_id
  ),
  announcement_totals as (
    select announcement.owner_id,
           count(*) as announcement_count,
           count(*) filter (
             where announcement.status = 'active'
               and announcement.moderation_status = 'published'
           ) as active_announcement_count
    from public.announcements announcement
    group by announcement.owner_id
  ),
  credit_totals as (
    select credit.user_id, count(*) as available_listing_credits
    from public.owner_listing_credits credit
    where credit.status = 'available'
    group by credit.user_id
  )
  select
    profile.id,
    profile.email,
    profile.full_name,
    profile.phone,
    profile.city,
    profile.created_at,
    coalesce(pet_totals.pet_count, 0),
    coalesce(visit_totals.visit_count, 0),
    coalesce(document_totals.document_count, 0),
    coalesce(announcement_totals.announcement_count, 0),
    coalesce(announcement_totals.active_announcement_count, 0),
    coalesce(entitlement.plan_code, 'free'),
    coalesce(entitlement.status, 'active'),
    entitlement.current_period_end,
    coalesce(credit_totals.available_listing_credits, 0),
    coalesce(auth_user.banned_until > now(), false)
  from public.profiles profile
  join auth.users auth_user on auth_user.id = profile.id
  left join pet_totals on pet_totals.owner_id = profile.id
  left join visit_totals on visit_totals.owner_id = profile.id
  left join document_totals on document_totals.owner_id = profile.id
  left join announcement_totals on announcement_totals.owner_id = profile.id
  left join public.owner_entitlements entitlement
    on entitlement.user_id = profile.id
    and entitlement.status in ('active', 'grace_period')
    and (
      entitlement.current_period_end is null
      or entitlement.current_period_end > now()
    )
  left join credit_totals on credit_totals.user_id = profile.id
  where profile.role <> 'platform_admin'
  order by profile.created_at desc;
end;
$$;

create or replace function public.admin_set_user_banned(
  target_user_id uuid,
  target_banned boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if target_user_id = auth.uid() then
    raise exception 'CANNOT_BLOCK_SELF';
  end if;
  if exists (
    select 1 from public.profiles
    where id = target_user_id and role = 'platform_admin'
  ) then
    raise exception 'CANNOT_BLOCK_ADMIN';
  end if;

  update auth.users
  set banned_until = case
    when target_banned then now() + interval '100 years'
    else null
  end
  where id = target_user_id;

  if not found then
    raise exception 'USER_NOT_FOUND';
  end if;

  insert into public.platform_admin_audit_log (
    admin_user_id, action, target_type, target_id, details
  )
  values (
    auth.uid(),
    case when target_banned then 'user_blocked' else 'user_unblocked' end,
    'user',
    target_user_id::text,
    jsonb_build_object('banned', target_banned)
  );
end;
$$;

create or replace function public.admin_set_owner_plan(
  target_user_id uuid,
  target_plan_code text,
  target_duration_days integer default 30
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  period_end timestamptz;
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if target_plan_code not in ('free', 'pro', 'pro_plus') then
    raise exception 'INVALID_PLAN';
  end if;
  if target_duration_days < 1 or target_duration_days > 3660 then
    raise exception 'INVALID_DURATION';
  end if;
  if not exists (
    select 1 from public.profiles where id = target_user_id
  ) then
    raise exception 'USER_NOT_FOUND';
  end if;

  period_end := case
    when target_plan_code = 'free' then null
    else now() + make_interval(days => target_duration_days)
  end;

  insert into public.owner_entitlements (
    user_id,
    plan_code,
    status,
    billing_period,
    provider,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    updated_at
  )
  values (
    target_user_id,
    target_plan_code,
    'active',
    'manual',
    'manual',
    now(),
    period_end,
    false,
    now()
  )
  on conflict (user_id) do update set
    plan_code = excluded.plan_code,
    status = 'active',
    billing_period = 'manual',
    provider = 'manual',
    product_id = null,
    provider_customer_id = null,
    provider_entitlement_id = null,
    current_period_start = now(),
    current_period_end = period_end,
    cancel_at_period_end = false,
    updated_at = now();

  insert into public.platform_admin_audit_log (
    admin_user_id, action, target_type, target_id, details
  )
  values (
    auth.uid(),
    'owner_plan_changed',
    'user',
    target_user_id::text,
    jsonb_build_object(
      'plan_code', target_plan_code,
      'duration_days', target_duration_days,
      'period_end', period_end
    )
  );
end;
$$;

create or replace function public.admin_grant_listing_credit(
  target_user_id uuid,
  target_tier text default 'standard'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  transaction_id uuid := gen_random_uuid();
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if target_tier not in ('standard', 'top_7', 'top_15') then
    raise exception 'INVALID_TIER';
  end if;
  if not exists (
    select 1 from public.profiles where id = target_user_id
  ) then
    raise exception 'USER_NOT_FOUND';
  end if;

  insert into public.owner_billing_transactions (
    id,
    user_id,
    provider,
    provider_transaction_id,
    product_id,
    purchase_kind,
    status,
    amount_minor,
    currency,
    purchased_at,
    verified_at,
    environment
  )
  values (
    transaction_id,
    target_user_id,
    'manual',
    'admin-grant-' || transaction_id::text,
    'admin.' || target_tier,
    'listing',
    'verified',
    0,
    'UAH',
    now(),
    now(),
    'admin'
  );

  insert into public.owner_listing_credits (
    user_id, transaction_id, tier, status
  )
  values (target_user_id, transaction_id, target_tier, 'available');

  insert into public.platform_admin_audit_log (
    admin_user_id, action, target_type, target_id, details
  )
  values (
    auth.uid(),
    'listing_credit_granted',
    'user',
    target_user_id::text,
    jsonb_build_object('tier', target_tier, 'transaction_id', transaction_id)
  );

  return transaction_id;
end;
$$;

revoke all on function public.admin_user_analytics()
  from public, anon;
revoke all on function public.admin_set_user_banned(uuid, boolean)
  from public, anon;
revoke all on function public.admin_set_owner_plan(uuid, text, integer)
  from public, anon;
revoke all on function public.admin_grant_listing_credit(uuid, text)
  from public, anon;

grant execute on function public.admin_user_analytics()
  to authenticated;
grant execute on function public.admin_set_user_banned(uuid, boolean)
  to authenticated;
grant execute on function public.admin_set_owner_plan(uuid, text, integer)
  to authenticated;
grant execute on function public.admin_grant_listing_credit(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
