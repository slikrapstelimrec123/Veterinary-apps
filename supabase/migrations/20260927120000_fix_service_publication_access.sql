-- Show the real number of available paid publication credits for service and
-- offer announcements instead of always returning zero.
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
  available_credits integer;
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
      'allowed', true,
      'free', true,
      'remaining', null,
      'requires_purchase', false,
      'plan', plan_data->>'code'
    );
  end if;

  if target_type in ('service', 'offer') then
    select count(*)::integer
      into available_credits
      from public.owner_listing_credits
     where user_id = auth.uid()
       and status = 'available';

    return jsonb_build_object(
      'allowed', available_credits > 0,
      'free', false,
      'remaining', available_credits,
      'requires_purchase', available_credits = 0,
      'plan', plan_data->>'code'
    );
  end if;

  plan_code := coalesce(plan_data->>'code', 'free');
  if plan_code = 'free' then
    category_limit := 1;
    select count(*)
      into used_count
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
    select count(*)
      into used_count
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

notify pgrst, 'reload schema';
