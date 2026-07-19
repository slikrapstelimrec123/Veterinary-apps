-- Expand the owner-published announcement board while keeping pet medical
-- records private and making the public feed efficient to query.

alter table public.announcements
  drop constraint if exists announcements_type_check;

alter table public.announcements
  alter column pet_id drop not null,
  alter column contact_name drop not null,
  alter column contact_phone drop not null,
  alter column breed drop not null,
  alter column pet_name drop not null,
  add column if not exists title text,
  add column if not exists address text,
  add column if not exists event_date timestamptz,
  add column if not exists contact_info text,
  add column if not exists service_category text,
  add column if not exists website text,
  add column if not exists offer_text text,
  add column if not exists valid_from date,
  add column if not exists valid_until date,
  add column if not exists promo_code text;

alter table public.announcements
  add constraint announcements_type_check check (
    announcement_type in ('sale', 'breeding', 'event', 'service', 'offer')
  ),
  add constraint announcements_service_category_check check (
    service_category is null
    or service_category in ('dog_trainer', 'groomer', 'pet_sitter', 'dog_hotel')
  ),
  add constraint announcements_validity_check check (
    valid_from is null or valid_until is null or valid_until >= valid_from
  ),
  add constraint announcements_category_fields_check check (
    (announcement_type in ('sale', 'breeding') and pet_id is not null)
    or (
      announcement_type = 'event'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and event_date is not null
    )
    or (
      announcement_type = 'service'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and service_category is not null
      and nullif(trim(contact_info), '') is not null
    )
    or (
      announcement_type = 'offer'
      and nullif(trim(title), '') is not null
      and nullif(trim(address), '') is not null
      and nullif(trim(offer_text), '') is not null
      and valid_until is not null
    )
  );

drop policy if exists "owners create announcements" on public.announcements;
create policy "owners create announcements"
on public.announcements for insert to authenticated
with check (
  owner_id = auth.uid()
  and (
    (announcement_type in ('sale', 'breeding') and public.owns_pet(pet_id))
    or (announcement_type in ('event', 'service', 'offer') and pet_id is null)
  )
  and moderation_status = 'published'
);

drop policy if exists "owners update announcements" on public.announcements;
create policy "owners update announcements"
on public.announcements for update to authenticated
using (owner_id = auth.uid())
with check (
  owner_id = auth.uid()
  and (
    (announcement_type in ('sale', 'breeding') and public.owns_pet(pet_id))
    or (announcement_type in ('event', 'service', 'offer') and pet_id is null)
  )
);

create index if not exists announcements_active_category_created_idx
  on public.announcements(announcement_type, created_at desc)
  where status = 'active' and moderation_status = 'published';

create index if not exists announcements_active_event_date_idx
  on public.announcements(event_date)
  where announcement_type = 'event'
    and status = 'active'
    and moderation_status = 'published';

create index if not exists announcements_active_offer_validity_idx
  on public.announcements(valid_until)
  where announcement_type = 'offer'
    and status = 'active'
    and moderation_status = 'published';

create or replace function public.fill_announcement_pet_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.pet_id is null then
    return new;
  end if;

  select
    pet.name,
    coalesce(pet.breed, new.breed),
    coalesce(nullif(lower(trim(pet.sex)), ''), 'unknown'),
    coalesce(pet.birth_date, new.birth_date),
    pet.avatar_url,
    pet.avatar_storage_path
  into
    new.pet_name,
    new.breed,
    new.gender,
    new.birth_date,
    new.photo_url,
    new.photo_storage_path
  from public.pets pet
  where pet.id = new.pet_id;

  return new;
end;
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'announcement-media',
  'announcement-media',
  false,
  3145728,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "owners upload announcement media" on storage.objects;
create policy "owners upload announcement media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'announcement-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "owners update announcement media" on storage.objects;
create policy "owners update announcement media"
on storage.objects for update to authenticated
using (
  bucket_id = 'announcement-media'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'announcement-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "owners delete announcement media" on storage.objects;
create policy "owners delete announcement media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'announcement-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.can_read_published_announcement_media(
  object_name text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.announcements
    where cover_photo_storage_path = object_name
      and announcement_type = 'event'
      and status = 'active'
      and moderation_status = 'published'
  );
$$;

revoke all on function public.can_read_published_announcement_media(text)
  from public, anon;
grant execute on function public.can_read_published_announcement_media(text)
  to authenticated;

drop policy if exists "users read published announcement media"
  on storage.objects;
create policy "users read published announcement media"
on storage.objects for select to authenticated
using (
  bucket_id = 'announcement-media'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.can_read_published_announcement_media(name)
  )
);

notify pgrst, 'reload schema';
