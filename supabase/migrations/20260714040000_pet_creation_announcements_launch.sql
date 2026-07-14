-- Aligns the live pet schema and launches owner-safe announcements.

alter table public.pets
  add column if not exists owner_id uuid references public.profiles(id);

update public.pets pet
set owner_id = ownership.user_id
from public.pet_owners ownership
where pet.owner_id is null
  and ownership.pet_id = pet.id
  and coalesce(ownership.is_primary, true) = true;

create or replace function public.create_pet_for_current_user(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  created_pet public.pets;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if nullif(trim(payload->>'name'), '') is null
     or nullif(trim(payload->>'species'), '') is null then
    raise exception 'Pet name and species are required';
  end if;

  insert into public.pets (
    owner_id, name, species, breed, sex, birth_date, weight_kg, color,
    microchip_number, avatar_url, avatar_storage_path, notes,
    is_neutered, passport_photo_url, passport_storage_path
  ) values (
    current_user_id,
    trim(payload->>'name'),
    trim(payload->>'species'),
    nullif(trim(payload->>'breed'), ''),
    nullif(trim(payload->>'sex'), ''),
    nullif(payload->>'birth_date', '')::date,
    nullif(payload->>'weight_kg', '')::numeric,
    nullif(trim(payload->>'color'), ''),
    nullif(trim(payload->>'microchip_number'), ''),
    nullif(trim(payload->>'avatar_url'), ''),
    nullif(trim(payload->>'avatar_storage_path'), ''),
    nullif(trim(payload->>'notes'), ''),
    nullif(payload->>'is_neutered', '')::boolean,
    nullif(trim(payload->>'passport_photo_url'), ''),
    nullif(trim(payload->>'passport_storage_path'), '')
  )
  returning * into created_pet;

  insert into public.pet_owners (
    pet_id, user_id, relationship, relationship_type, is_primary
  ) values (
    created_pet.id, current_user_id, 'primary_owner', 'primary_owner', true
  )
  on conflict (pet_id, user_id) do update set is_primary = true;

  return to_jsonb(created_pet);
end;
$$;

revoke all on function public.create_pet_for_current_user(jsonb) from public, anon;
grant execute on function public.create_pet_for_current_user(jsonb) to authenticated;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  announcement_type text not null,
  contact_name text not null,
  contact_phone text not null,
  breed text not null,
  pet_name text not null,
  gender text,
  birth_date date,
  age_years integer,
  price_amount integer,
  photo_url text,
  color text,
  has_vaccinations boolean,
  has_pedigree boolean,
  has_chip boolean,
  desired_breed text,
  conditions text,
  description text,
  city text,
  status text not null default 'active',
  moderation_status text not null default 'published',
  report_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcements_type_check check (announcement_type in ('sale', 'breeding')),
  constraint announcements_status_check check (status in ('active', 'inactive')),
  constraint announcements_moderation_check check (moderation_status in ('published', 'review', 'blocked')),
  constraint announcements_price_check check (price_amount is null or price_amount >= 0),
  constraint announcements_age_check check (age_years is null or age_years between 0 and 40)
);

create table if not exists public.announcement_reports (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz not null default now(),
  unique (announcement_id, reporter_id),
  constraint announcement_reports_reason_check check (
    reason in ('inappropriate_content', 'fraud', 'animal_welfare', 'spam', 'other')
  )
);

create table if not exists public.announcement_user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id),
  constraint announcement_user_blocks_self_check check (blocker_id <> blocked_user_id)
);

create index if not exists announcements_public_feed_idx
  on public.announcements(announcement_type, status, moderation_status, created_at desc);
create index if not exists announcements_owner_idx
  on public.announcements(owner_id, status, created_at desc);

alter table public.announcements enable row level security;
alter table public.announcement_reports enable row level security;
alter table public.announcement_user_blocks enable row level security;

drop policy if exists "users read safe announcements" on public.announcements;
drop policy if exists "owners create announcements" on public.announcements;
drop policy if exists "owners update announcements" on public.announcements;
drop policy if exists "owners delete announcements" on public.announcements;

create policy "users read safe announcements"
on public.announcements for select to authenticated
using (
  owner_id = auth.uid()
  or (
    status = 'active'
    and moderation_status = 'published'
    and not exists (
      select 1 from public.announcement_user_blocks block
      where block.blocker_id = auth.uid()
        and block.blocked_user_id = announcements.owner_id
    )
  )
);

create policy "owners create announcements"
on public.announcements for insert to authenticated
with check (
  owner_id = auth.uid()
  and public.owns_pet(pet_id)
  and moderation_status = 'published'
);

create policy "owners update announcements"
on public.announcements for update to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid() and public.owns_pet(pet_id));

create policy "owners delete announcements"
on public.announcements for delete to authenticated
using (owner_id = auth.uid());

drop policy if exists "users create own reports" on public.announcement_reports;
drop policy if exists "users read own reports" on public.announcement_reports;
create policy "users create own reports"
on public.announcement_reports for insert to authenticated
with check (
  reporter_id = auth.uid()
  and exists (
    select 1 from public.announcements announcement
    where announcement.id = announcement_id
      and announcement.owner_id <> auth.uid()
  )
);
create policy "users read own reports"
on public.announcement_reports for select to authenticated
using (reporter_id = auth.uid());

drop policy if exists "users manage own blocks" on public.announcement_user_blocks;
create policy "users manage own blocks"
on public.announcement_user_blocks for all to authenticated
using (blocker_id = auth.uid())
with check (blocker_id = auth.uid());

create or replace function public.refresh_announcement_report_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  reports integer;
begin
  select count(*) into reports
  from public.announcement_reports
  where announcement_id = new.announcement_id;

  update public.announcements
  set report_count = reports,
      moderation_status = case when reports >= 3 then 'review' else moderation_status end,
      updated_at = now()
  where id = new.announcement_id;
  return new;
end;
$$;

drop trigger if exists announcement_report_count_changed on public.announcement_reports;
create trigger announcement_report_count_changed
after insert on public.announcement_reports
for each row execute function public.refresh_announcement_report_count();

revoke all on function public.refresh_announcement_report_count() from public, anon, authenticated;
grant select, insert, update, delete on public.announcements to authenticated;
grant select, insert on public.announcement_reports to authenticated;
grant select, insert, delete on public.announcement_user_blocks to authenticated;
