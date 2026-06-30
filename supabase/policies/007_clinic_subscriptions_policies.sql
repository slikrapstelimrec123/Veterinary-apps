-- Clinic subscription plans, usage, and upgrade requests RLS.
-- Payment provider integration is intentionally not implemented in this stage.

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
