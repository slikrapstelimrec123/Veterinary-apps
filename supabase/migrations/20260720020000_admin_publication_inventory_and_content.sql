-- Give platform administrators an accurate, auditable view of accounts,
-- publication credits, and deliberately published announcement content.

drop function if exists public.admin_user_analytics();

create function public.admin_user_analytics()
returns table (
  user_id uuid,
  email text,
  full_name text,
  phone text,
  city text,
  created_at timestamptz,
  role text,
  pet_count bigint,
  visit_count bigint,
  document_count bigint,
  announcement_count bigint,
  active_announcement_count bigint,
  plan_code text,
  plan_status text,
  plan_end timestamptz,
  available_listing_credits bigint,
  standard_listing_credits bigint,
  top_7_listing_credits bigint,
  top_15_listing_credits bigint,
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
    join public.visit_documents document
      on document.visit_record_id = visit.id
    group by pet.owner_id
  ),
  announcement_totals as (
    select
      announcement.owner_id,
      count(*) as announcement_count,
      count(*) filter (
        where announcement.status = 'active'
          and announcement.moderation_status = 'published'
      ) as active_announcement_count
    from public.announcements announcement
    group by announcement.owner_id
  ),
  credit_totals as (
    select
      credit.user_id,
      count(*) as available_listing_credits,
      count(*) filter (where credit.tier = 'standard')
        as standard_listing_credits,
      count(*) filter (where credit.tier = 'top_7')
        as top_7_listing_credits,
      count(*) filter (where credit.tier = 'top_15')
        as top_15_listing_credits
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
    profile.role,
    coalesce(pet_totals.pet_count, 0),
    coalesce(visit_totals.visit_count, 0),
    coalesce(document_totals.document_count, 0),
    coalesce(announcement_totals.announcement_count, 0),
    coalesce(announcement_totals.active_announcement_count, 0),
    coalesce(entitlement.plan_code, 'free'),
    coalesce(entitlement.status, 'active'),
    entitlement.current_period_end,
    coalesce(credit_totals.available_listing_credits, 0),
    coalesce(credit_totals.standard_listing_credits, 0),
    coalesce(credit_totals.top_7_listing_credits, 0),
    coalesce(credit_totals.top_15_listing_credits, 0),
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
  order by profile.created_at desc;
end;
$$;

create or replace function public.admin_revoke_listing_credit(
  target_user_id uuid,
  target_tier text default 'standard'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  credit_id uuid;
  billing_transaction_id uuid;
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if target_tier not in ('standard', 'top_7', 'top_15') then
    raise exception 'INVALID_TIER';
  end if;

  select credit.id, credit.transaction_id
  into credit_id, billing_transaction_id
  from public.owner_listing_credits credit
  join public.owner_billing_transactions transaction
    on transaction.id = credit.transaction_id
  where credit.user_id = target_user_id
    and credit.tier = target_tier
    and credit.status = 'available'
    and transaction.provider = 'manual'
    and transaction.environment = 'admin'
  order by credit.created_at desc
  limit 1
  for update of credit;

  if credit_id is null then
    raise exception 'NO_ADMIN_GRANTED_CREDIT';
  end if;

  update public.owner_listing_credits
  set status = 'expired'
  where id = credit_id;

  update public.owner_billing_transactions
  set status = 'revoked'
  where id = billing_transaction_id;

  insert into public.platform_admin_audit_log (
    admin_user_id, action, target_type, target_id, details
  )
  values (
    auth.uid(),
    'listing_credit_revoked',
    'user',
    target_user_id::text,
    jsonb_build_object(
      'tier', target_tier,
      'credit_id', credit_id,
      'transaction_id', billing_transaction_id
    )
  );

  return credit_id;
end;
$$;

create or replace function public.admin_announcement_analytics()
returns table (
  announcement_id uuid,
  owner_id uuid,
  owner_email text,
  owner_name text,
  announcement_type text,
  title text,
  summary text,
  city text,
  status text,
  moderation_status text,
  publication_tier text,
  publication_source text,
  view_count bigint,
  created_at timestamptz,
  publication_expires_at timestamptz,
  details jsonb
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
  select
    announcement.id,
    announcement.owner_id,
    profile.email,
    profile.full_name,
    announcement.announcement_type,
    coalesce(
      nullif(trim(announcement.title), ''),
      nullif(trim(announcement.pet_name), ''),
      nullif(trim(announcement.breed), ''),
      'Без назви'
    ),
    coalesce(
      nullif(trim(announcement.description), ''),
      nullif(trim(announcement.offer_text), ''),
      nullif(trim(announcement.conditions), '')
    ),
    announcement.city,
    announcement.status,
    announcement.moderation_status,
    announcement.publication_tier,
    announcement.publication_source,
    coalesce(metrics.view_count, 0),
    announcement.created_at,
    announcement.publication_expires_at,
    jsonb_strip_nulls(jsonb_build_object(
      'pet_name', announcement.pet_name,
      'breed', announcement.breed,
      'gender', announcement.gender,
      'birth_date', announcement.birth_date,
      'price_amount', announcement.price_amount,
      'desired_breed', announcement.desired_breed,
      'address', announcement.address,
      'event_date', announcement.event_date,
      'service_category', announcement.service_category,
      'offer_category', announcement.offer_category,
      'website', announcement.website,
      'offer_text', announcement.offer_text,
      'valid_from', announcement.valid_from,
      'valid_until', announcement.valid_until,
      'promo_code', announcement.promo_code,
      'contact_name', announcement.contact_name,
      'contact_phone', announcement.contact_phone,
      'contact_info', announcement.contact_info
    ))
  from public.announcements announcement
  join public.profiles profile on profile.id = announcement.owner_id
  left join public.announcement_owner_metrics metrics
    on metrics.announcement_id = announcement.id
  order by announcement.created_at desc;
end;
$$;

revoke all on function public.admin_user_analytics()
  from public, anon;
revoke all on function public.admin_revoke_listing_credit(uuid, text)
  from public, anon;
revoke all on function public.admin_announcement_analytics()
  from public, anon;

grant execute on function public.admin_user_analytics()
  to authenticated;
grant execute on function public.admin_revoke_listing_credit(uuid, text)
  to authenticated;
grant execute on function public.admin_announcement_analytics()
  to authenticated;

notify pgrst, 'reload schema';
