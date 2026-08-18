-- Let an authenticated owner remove obsolete notifications from their inbox
-- without deleting the underlying audit row.

create or replace function public.archive_my_notification(
  target_notification_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_count integer;
begin
  update public.notifications
  set status = 'archived',
      updated_at = now()
  where id = target_notification_id
    and user_id = auth.uid()
    and status <> 'archived';

  get diagnostics changed_count = row_count;
  return changed_count;
end;
$$;

revoke all on function public.archive_my_notification(uuid)
  from public, anon;
grant execute on function public.archive_my_notification(uuid)
  to authenticated;
