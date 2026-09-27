-- Move offers to the inactive state as soon as their calendar end date passes.
-- The scheduled lifecycle job remains the source of truth for persisted status;
-- the mobile repository also applies the same rule immediately while reading.

update public.announcements
set status = 'inactive', updated_at = now()
where status = 'active'
  and announcement_type = 'offer'
  and valid_until < current_date;

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
    and (
      publication_expires_at <= now()
      or (
        announcement_type = 'offer'
        and valid_until < current_date
      )
    );
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

-- Defense in depth: do not expose an expired offer through a direct
-- Supabase query even before the scheduled lifecycle job changes its status.
drop policy if exists "users read safe announcements" on public.announcements;
create policy "users read safe announcements"
on public.announcements for select to authenticated
using (
  owner_id = auth.uid()
  or (
    status = 'active'
    and moderation_status = 'published'
    and (
      announcement_type <> 'offer'
      or valid_until is null
      or valid_until >= current_date
    )
    and not exists (
      select 1
      from public.announcement_user_blocks block
      where block.blocker_id = auth.uid()
        and block.blocked_user_id = announcements.owner_id
    )
  )
);
