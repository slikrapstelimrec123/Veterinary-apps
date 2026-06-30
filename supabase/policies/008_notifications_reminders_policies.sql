-- Notifications and reminders RLS policy reference.
-- In-app delivery is implemented; external providers remain placeholders.

drop policy if exists "users read own notifications" on notifications;
drop policy if exists "users update own notification status" on notifications;
drop policy if exists "platform admins read notifications" on notifications;
drop policy if exists "users read own notification preferences" on notification_preferences;
drop policy if exists "users update own notification preferences" on notification_preferences;
drop policy if exists "users insert own notification preferences" on notification_preferences;
drop policy if exists "platform admins read notification preferences" on notification_preferences;
drop policy if exists "platform admins read delivery logs" on notification_delivery_log;
drop policy if exists "users read own scheduled notifications" on scheduled_notifications;
drop policy if exists "platform admins manage scheduled notifications" on scheduled_notifications;

create policy "users read own notifications"
on notifications for select
using (recipient_user_id = auth.uid() or public.is_platform_admin());

create policy "users update own notification status"
on notifications for update
using (recipient_user_id = auth.uid())
with check (recipient_user_id = auth.uid() and status in ('unread', 'read', 'archived'));

create policy "platform admins read notifications"
on notifications for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "users read own notification preferences"
on notification_preferences for select
using (user_id = auth.uid() or public.is_platform_admin());

create policy "users insert own notification preferences"
on notification_preferences for insert
with check (user_id = auth.uid());

create policy "users update own notification preferences"
on notification_preferences for update
using (user_id = auth.uid())
with check (user_id = auth.uid() and marketing_enabled = false);

create policy "platform admins read notification preferences"
on notification_preferences for select
using (public.is_platform_admin());

create policy "platform admins read delivery logs"
on notification_delivery_log for select
using (public.is_platform_admin());

create policy "users read own scheduled notifications"
on scheduled_notifications for select
using (recipient_user_id = auth.uid() or public.is_platform_admin());

create policy "platform admins manage scheduled notifications"
on scheduled_notifications for all
using (public.is_platform_admin())
with check (public.is_platform_admin());
