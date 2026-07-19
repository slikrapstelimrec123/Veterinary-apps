-- Add structured discovery filters and privacy-preserving owner metrics.

alter table public.announcements
  add column if not exists offer_category text;

update public.announcements
set city = coalesce(
  nullif(trim(city), ''),
  nullif(trim(split_part(address, ',', 1)), ''),
  'Онлайн'
)
where announcement_type in ('event', 'service', 'offer')
  and nullif(trim(city), '') is null;

update public.announcements
set description = coalesce(
  nullif(trim(description), ''),
  nullif(trim(offer_text), ''),
  title
)
where announcement_type in ('event', 'service', 'offer')
  and nullif(trim(description), '') is null;

update public.announcements
set offer_category = 'other'
where announcement_type = 'offer'
  and offer_category is null;

alter table public.announcements
  drop constraint if exists announcements_offer_category_check,
  drop constraint if exists announcements_category_fields_check;

alter table public.announcements
  add constraint announcements_offer_category_check check (
    offer_category is null
    or offer_category in ('shop', 'clinic', 'other')
  ),
  add constraint announcements_category_fields_check check (
    (announcement_type in ('sale', 'breeding') and pet_id is not null)
    or (
      announcement_type = 'event'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and nullif(trim(city), '') is not null
      and nullif(trim(description), '') is not null
      and event_date is not null
    )
    or (
      announcement_type = 'service'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and nullif(trim(city), '') is not null
      and nullif(trim(description), '') is not null
      and service_category is not null
      and nullif(trim(contact_info), '') is not null
    )
    or (
      announcement_type = 'offer'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and nullif(trim(city), '') is not null
      and nullif(trim(description), '') is not null
      and offer_category is not null
      and nullif(trim(website), '') is not null
      and nullif(trim(offer_text), '') is not null
      and valid_until is not null
    )
  );

create index if not exists announcements_active_event_city_date_idx
  on public.announcements(city, event_date)
  where announcement_type = 'event'
    and status = 'active'
    and moderation_status = 'published';

create index if not exists announcements_active_service_filters_idx
  on public.announcements(city, service_category, created_at desc)
  where announcement_type = 'service'
    and status = 'active'
    and moderation_status = 'published';

create index if not exists announcements_active_offer_filters_idx
  on public.announcements(city, offer_category, valid_until)
  where announcement_type = 'offer'
    and status = 'active'
    and moderation_status = 'published';

create table if not exists public.announcement_owner_metrics (
  announcement_id uuid primary key
    references public.announcements(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  view_count bigint not null default 0 check (view_count >= 0),
  updated_at timestamptz not null default now()
);

-- A view is counted once per authenticated viewer. This prevents refreshes from
-- inflating counters and avoids repeated writes that consume database quota.
create table if not exists public.announcement_unique_viewers (
  announcement_id uuid not null
    references public.announcements(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  first_viewed_at timestamptz not null default now(),
  primary key (announcement_id, viewer_id)
);

alter table public.announcement_owner_metrics enable row level security;
alter table public.announcement_unique_viewers enable row level security;

drop policy if exists "owners read announcement metrics"
  on public.announcement_owner_metrics;
create policy "owners read announcement metrics"
on public.announcement_owner_metrics for select to authenticated
using (owner_id = auth.uid());

revoke all on public.announcement_owner_metrics from anon;
revoke all on public.announcement_unique_viewers from anon, authenticated;
grant select on public.announcement_owner_metrics to authenticated;

create or replace function public.record_announcement_view(
  p_announcement_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_owner_id uuid;
  inserted_rows integer;
begin
  if auth.uid() is null then
    return;
  end if;

  select announcement.owner_id
  into target_owner_id
  from public.announcements announcement
  where announcement.id = p_announcement_id
    and announcement.status = 'active'
    and announcement.moderation_status = 'published';

  if target_owner_id is null or target_owner_id = auth.uid() then
    return;
  end if;

  insert into public.announcement_unique_viewers (
    announcement_id,
    viewer_id
  )
  values (p_announcement_id, auth.uid())
  on conflict do nothing;

  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then
    return;
  end if;

  insert into public.announcement_owner_metrics (
    announcement_id,
    owner_id,
    view_count
  )
  values (p_announcement_id, target_owner_id, 1)
  on conflict (announcement_id) do update
  set
    view_count = public.announcement_owner_metrics.view_count + 1,
    updated_at = now();
end;
$$;

revoke all on function public.record_announcement_view(uuid)
  from public, anon;
grant execute on function public.record_announcement_view(uuid)
  to authenticated;

notify pgrst, 'reload schema';
