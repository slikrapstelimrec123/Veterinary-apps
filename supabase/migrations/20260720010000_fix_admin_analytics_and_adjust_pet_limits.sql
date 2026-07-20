-- Fix the private admin analytics query and align owner plan pet limits with
-- the current product rules.

update public.owner_plan_catalog
set
  pet_limit = case code
    when 'free' then 2
    when 'pro' then 5
    when 'pro_plus' then 20
    else pet_limit
  end,
  updated_at = now()
where code in ('free', 'pro', 'pro_plus');

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

revoke all on function public.admin_user_analytics()
  from public, anon;
grant execute on function public.admin_user_analytics()
  to authenticated;

notify pgrst, 'reload schema';
