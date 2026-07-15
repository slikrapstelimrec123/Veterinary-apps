-- Realtime local alerts and durable, access-controlled photos for published listings.

alter table public.announcements
  add column if not exists photo_storage_path text;

update public.announcements announcement
set photo_storage_path = pet.avatar_storage_path
from public.pets pet
where announcement.pet_id = pet.id
  and announcement.photo_storage_path is null
  and pet.avatar_storage_path is not null;

create or replace function public.can_read_published_announcement_photo(
  object_name text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.announcements
    where photo_storage_path = object_name
      and status = 'active'
      and moderation_status = 'published'
  );
$$;

revoke all on function public.can_read_published_announcement_photo(text)
  from public, anon;
grant execute on function public.can_read_published_announcement_photo(text)
  to authenticated;

drop policy if exists "authenticated read published announcement photos"
  on storage.objects;
create policy "authenticated read published announcement photos"
on storage.objects for select
to authenticated
using (
  bucket_id = 'pet-documents'
  and public.can_read_published_announcement_photo(name)
);

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end
$$;
