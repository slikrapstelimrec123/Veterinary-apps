-- Realtime local alerts and durable, access-controlled photos for published listings.

alter table public.pet_achievements
  add column if not exists award_image_url text,
  add column if not exists event_photo_url text,
  add column if not exists award_image_path text,
  add column if not exists event_photo_path text;

alter table public.notifications
  add column if not exists pet_id uuid references public.pets(id) on delete set null,
  add column if not exists data jsonb not null default '{}'::jsonb;

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

create or replace function public.notify_pet_transfer_recipient()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  pet_name text;
begin
  if new.to_user_id is null then
    return new;
  end if;

  select name into pet_name from public.pets where id = new.pet_id;
  insert into public.notifications (
    user_id,
    pet_id,
    type,
    title,
    body,
    data
  ) values (
    new.to_user_id,
    new.pet_id,
    'pet_transfer_request',
    'Запит на передачу тварини',
    coalesce(pet_name, 'Тварину') || ' пропонують передати до вашого акаунта.',
    jsonb_build_object('transfer_id', new.id)
  );
  return new;
end;
$$;

drop trigger if exists notify_pet_transfer_recipient
  on public.pet_transfers;
create trigger notify_pet_transfer_recipient
after insert on public.pet_transfers
for each row execute function public.notify_pet_transfer_recipient();

insert into public.notifications (
  user_id,
  pet_id,
  type,
  title,
  body,
  data
)
select
  transfer.to_user_id,
  transfer.pet_id,
  'pet_transfer_request',
  'Запит на передачу тварини',
  coalesce(pet.name, 'Тварину') || ' пропонують передати до вашого акаунта.',
  jsonb_build_object('transfer_id', transfer.id)
from public.pet_transfers transfer
left join public.pets pet on pet.id = transfer.pet_id
where transfer.status = 'pending'
  and transfer.to_user_id is not null
  and not exists (
    select 1
    from public.notifications notification
    where notification.type = 'pet_transfer_request'
      and notification.data->>'transfer_id' = transfer.id::text
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

  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'announcements'
  ) then
    alter publication supabase_realtime add table public.announcements;
  end if;

  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'pet_transfers'
  ) then
    alter publication supabase_realtime add table public.pet_transfers;
  end if;
end
$$;

notify pgrst, 'reload schema';
