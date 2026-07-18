-- Keep the public pet snapshot separate from the optional announcement cover
-- and make ownership transfers complete atomically for the recipient.

alter table public.announcements
  add column if not exists cover_photo_url text,
  add column if not exists cover_photo_storage_path text;

-- Existing custom announcement images become covers. The regular photo fields
-- are restored to the current pet-card avatar below.
update public.announcements
set cover_photo_url = coalesce(cover_photo_url, photo_url),
    cover_photo_storage_path =
      coalesce(cover_photo_storage_path, photo_storage_path);

update public.announcements announcement
set photo_url = pet.avatar_url,
    photo_storage_path = pet.avatar_storage_path,
    pet_name = pet.name,
    breed = coalesce(pet.breed, announcement.breed),
    gender = coalesce(nullif(lower(trim(pet.sex)), ''), 'unknown'),
    birth_date = coalesce(pet.birth_date, announcement.birth_date),
    updated_at = now()
from public.pets pet
where pet.id = announcement.pet_id;

create or replace function public.fill_announcement_pet_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
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

drop trigger if exists fill_announcement_pet_photo on public.announcements;
drop trigger if exists fill_announcement_pet_snapshot on public.announcements;
create trigger fill_announcement_pet_snapshot
before insert or update of pet_id
on public.announcements
for each row execute function public.fill_announcement_pet_snapshot();

create or replace function public.sync_pet_snapshot_to_announcements()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.announcements
  set pet_name = new.name,
      breed = coalesce(new.breed, announcements.breed),
      gender = coalesce(nullif(lower(trim(new.sex)), ''), 'unknown'),
      birth_date = coalesce(new.birth_date, announcements.birth_date),
      photo_url = new.avatar_url,
      photo_storage_path = new.avatar_storage_path,
      updated_at = now()
  where pet_id = new.id;
  return new;
end;
$$;

drop trigger if exists sync_pet_photo_to_announcements on public.pets;
drop trigger if exists sync_pet_snapshot_to_announcements on public.pets;
create trigger sync_pet_snapshot_to_announcements
after update of name, breed, sex, birth_date, avatar_storage_path, avatar_url
on public.pets
for each row execute function public.sync_pet_snapshot_to_announcements();

create or replace function public.can_read_published_announcement_photo(
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
    where (
        photo_storage_path = object_name
        or cover_photo_storage_path = object_name
      )
      and status = 'active'
      and moderation_status = 'published'
  );
$$;

revoke all on function public.can_read_published_announcement_photo(text)
  from public, anon;
grant execute on function public.can_read_published_announcement_photo(text)
  to authenticated;

create or replace function public.accept_pet_transfer(transfer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  transfer_record public.pet_transfers%rowtype;
  current_user_id uuid := auth.uid();
  current_email text := lower(coalesce(auth.jwt()->>'email', ''));
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into transfer_record
  from public.pet_transfers
  where id = transfer_id
  for update;

  if transfer_record.id is null
     or transfer_record.status <> 'pending'
     or (
       transfer_record.to_user_id is distinct from current_user_id
       and lower(trim(transfer_record.to_email)) <> current_email
     ) then
    raise exception 'Transfer is not available';
  end if;

  -- Establish recipient access first so ownership-dependent triggers and
  -- policies always see a valid primary owner during the transition.
  insert into public.pet_owners (
    pet_id, user_id, relationship, relationship_type, is_primary
  ) values (
    transfer_record.pet_id,
    current_user_id,
    'primary_owner',
    'primary_owner',
    true
  )
  on conflict (pet_id, user_id) do update set
    relationship = excluded.relationship,
    relationship_type = excluded.relationship_type,
    is_primary = excluded.is_primary;

  update public.pets
  set owner_id = current_user_id,
      updated_at = now()
  where id = transfer_record.pet_id
    and owner_id = transfer_record.from_user_id;

  if not found then
    raise exception 'Pet ownership has changed';
  end if;

  delete from public.pet_owners
  where pet_id = transfer_record.pet_id
    and user_id <> current_user_id;

  update public.visit_records
  set owner_id = current_user_id,
      updated_at = now()
  where pet_id = transfer_record.pet_id;

  update public.announcements
  set status = 'inactive',
      updated_at = now()
  where pet_id = transfer_record.pet_id
    and owner_id = transfer_record.from_user_id
    and status = 'active';

  update public.pet_transfers
  set to_user_id = current_user_id,
      status = 'accepted',
      responded_at = now(),
      updated_at = now()
  where id = transfer_record.id;

  -- Notification cleanup must never roll back a completed ownership transfer.
  begin
    update public.notifications
    set status = 'read',
        read_at = coalesce(read_at, now()),
        updated_at = now()
    where user_id = current_user_id
      and type = 'pet_transfer_request'
      and data->>'transfer_id' = transfer_record.id::text;

    update public.notifications
    set status = 'archived',
        updated_at = now()
    where user_id = transfer_record.from_user_id
      and pet_id = transfer_record.pet_id
      and status <> 'archived';
  exception
    when others then
      null;
  end;
end;
$$;

revoke all on function public.accept_pet_transfer(uuid) from public, anon;
grant execute on function public.accept_pet_transfer(uuid) to authenticated;

notify pgrst, 'reload schema';
