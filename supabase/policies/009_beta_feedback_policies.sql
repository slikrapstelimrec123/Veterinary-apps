-- Beta feedback RLS policy reference.

drop policy if exists "users create own beta feedback" on beta_feedback;
drop policy if exists "users read own beta feedback" on beta_feedback;
drop policy if exists "platform admins manage beta feedback" on beta_feedback;

create policy "users create own beta feedback"
on beta_feedback for insert
with check (user_id = auth.uid());

create policy "users read own beta feedback"
on beta_feedback for select
using (user_id = auth.uid() or public.is_platform_admin());

create policy "platform admins manage beta feedback"
on beta_feedback for all
using (public.is_platform_admin())
with check (public.is_platform_admin());
