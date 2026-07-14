-- Mobile release foundation: owner-safe pet creation, private uploads,
-- pet care modules, and transactional ownership transfers.

alter table public.pets
  add column if not exists is_neutered boolean,
  add column if not exists passport_photo_url text,
  add column if not exists avatar_storage_path text,
  add column if not exists passport_storage_path text;

create or replace function public.create_pet_for_current_user(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  created_pet public.pets;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if nullif(trim(payload->>'name'), '') is null
     or nullif(trim(payload->>'species'), '') is null then
    raise exception 'Pet name and species are required';
  end if;

  insert into public.pets (
    name, species, breed, sex, birth_date, weight_kg, color,
    microchip_number, avatar_url, avatar_storage_path, notes,
    is_neutered, passport_photo_url, passport_storage_path
  ) values (
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
    created_pet.id, auth.uid(), 'primary_owner', 'primary_owner', true
  );

  return to_jsonb(created_pet);
end;
$$;

revoke all on function public.create_pet_for_current_user(jsonb) from public;
grant execute on function public.create_pet_for_current_user(jsonb) to authenticated;

drop policy if exists "pet owners delete own pets" on public.pets;
create policy "pet owners delete own pets" on public.pets
for delete to authenticated using (public.owns_pet(id));

create table if not exists public.pet_medications (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  name text not null,
  given_date date not null,
  dosage text,
  category text,
  notes text,
  next_dose_date date,
  reminder_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pet_feedings (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  food_name text not null,
  brand text,
  food_type text,
  start_date date not null,
  end_date date,
  notes text,
  rating integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_feedings_date_check check (end_date is null or end_date >= start_date),
  constraint pet_feedings_rating_check check (rating is null or rating between 1 and 5)
);

create table if not exists public.pet_achievements (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  title text not null,
  event_date date not null,
  end_date date,
  event_type text,
  location text,
  result text,
  award_title text,
  award_image_url text,
  event_photo_url text,
  award_image_path text,
  event_photo_path text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_achievements_date_check check (end_date is null or end_date >= event_date)
);

create index if not exists pet_medications_pet_date_idx
  on public.pet_medications(pet_id, given_date desc);
create index if not exists pet_feedings_pet_date_idx
  on public.pet_feedings(pet_id, start_date desc);
create index if not exists pet_achievements_pet_date_idx
  on public.pet_achievements(pet_id, event_date desc);

alter table public.pet_medications enable row level security;
alter table public.pet_feedings enable row level security;
alter table public.pet_achievements enable row level security;

drop policy if exists "owners manage pet medications" on public.pet_medications;
create policy "owners manage pet medications" on public.pet_medications
for all using (public.owns_pet(pet_id)) with check (public.owns_pet(pet_id));

drop policy if exists "owners manage pet feedings" on public.pet_feedings;
create policy "owners manage pet feedings" on public.pet_feedings
for all using (public.owns_pet(pet_id)) with check (public.owns_pet(pet_id));

drop policy if exists "owners manage pet achievements" on public.pet_achievements;
create policy "owners manage pet achievements" on public.pet_achievements
for all using (public.owns_pet(pet_id)) with check (public.owns_pet(pet_id));

drop trigger if exists set_pet_medications_updated_at on public.pet_medications;
create trigger set_pet_medications_updated_at before update on public.pet_medications
for each row execute function public.set_updated_at();
drop trigger if exists set_pet_feedings_updated_at on public.pet_feedings;
create trigger set_pet_feedings_updated_at before update on public.pet_feedings
for each row execute function public.set_updated_at();
drop trigger if exists set_pet_achievements_updated_at on public.pet_achievements;
create trigger set_pet_achievements_updated_at before update on public.pet_achievements
for each row execute function public.set_updated_at();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pet-documents',
  'pet-documents',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/heic', 'image/heif', 'application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.pet_id_from_storage_path(object_name text)
returns uuid
language plpgsql
immutable
as $$
declare
  value text;
begin
  value := (storage.foldername(object_name))[2];
  if value is null or value !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return null;
  end if;
  return value::uuid;
end;
$$;

drop policy if exists "owners read private pet files" on storage.objects;
create policy "owners read private pet files" on storage.objects
for select to authenticated using (
  bucket_id = 'pet-documents'
  and public.owns_pet(public.pet_id_from_storage_path(name))
);

drop policy if exists "owners upload private pet files" on storage.objects;
create policy "owners upload private pet files" on storage.objects
for insert to authenticated with check (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.owns_pet(public.pet_id_from_storage_path(name))
);

drop policy if exists "owners update private pet files" on storage.objects;
create policy "owners update private pet files" on storage.objects
for update to authenticated using (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.owns_pet(public.pet_id_from_storage_path(name))
) with check (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.owns_pet(public.pet_id_from_storage_path(name))
);

drop policy if exists "owners delete private pet files" on storage.objects;
create policy "owners delete private pet files" on storage.objects
for delete to authenticated using (
  bucket_id = 'pet-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.owns_pet(public.pet_id_from_storage_path(name))
);

create table if not exists public.pet_transfers (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_email text not null,
  to_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'pending',
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_transfers_status_check check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  constraint pet_transfers_email_check check (position('@' in to_email) > 1)
);

create unique index if not exists pet_transfers_one_pending_per_pet_idx
  on public.pet_transfers(pet_id) where status = 'pending';
create index if not exists pet_transfers_recipient_idx
  on public.pet_transfers(lower(to_email), status, created_at desc);

alter table public.pet_transfers enable row level security;

drop policy if exists "transfer participants read transfers" on public.pet_transfers;
create policy "transfer participants read transfers" on public.pet_transfers
for select to authenticated using (
  from_user_id = auth.uid()
  or to_user_id = auth.uid()
  or lower(to_email) = lower(coalesce(auth.jwt()->>'email', ''))
);

drop policy if exists "owners create transfers" on public.pet_transfers;
create policy "owners create transfers" on public.pet_transfers
for insert to authenticated with check (
  from_user_id = auth.uid()
  and public.owns_pet(pet_id)
  and status = 'pending'
  and lower(to_email) <> lower(coalesce(auth.jwt()->>'email', ''))
);

drop policy if exists "senders cancel transfers" on public.pet_transfers;
create policy "senders cancel transfers" on public.pet_transfers
for update to authenticated using (
  from_user_id = auth.uid() and status = 'pending'
) with check (
  from_user_id = auth.uid() and status = 'cancelled'
);

drop policy if exists "transfer recipients read sender profile" on public.profiles;
create policy "transfer recipients read sender profile" on public.profiles
for select to authenticated using (
  exists (
    select 1 from public.pet_transfers transfer
    where transfer.from_user_id = profiles.id
      and transfer.status = 'pending'
      and (
        transfer.to_user_id = auth.uid()
        or lower(transfer.to_email) = lower(coalesce(auth.jwt()->>'email', ''))
      )
  )
);

create or replace function public.resolve_pet_transfer_recipient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.to_email := lower(trim(new.to_email));
  select id into new.to_user_id
  from public.profiles
  where lower(email) = new.to_email
  limit 1;
  return new;
end;
$$;

drop trigger if exists resolve_pet_transfer_recipient on public.pet_transfers;
create trigger resolve_pet_transfer_recipient
before insert or update of to_email on public.pet_transfers
for each row execute function public.resolve_pet_transfer_recipient();

drop trigger if exists set_pet_transfers_updated_at on public.pet_transfers;
create trigger set_pet_transfers_updated_at before update on public.pet_transfers
for each row execute function public.set_updated_at();

create or replace function public.accept_pet_transfer(transfer_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  transfer public.pet_transfers;
begin
  select * into transfer from public.pet_transfers
  where id = transfer_id for update;

  if transfer.id is null or transfer.status <> 'pending' then
    raise exception 'Transfer is not available';
  end if;
  if auth.uid() is null or (
    transfer.to_user_id is distinct from auth.uid()
    and lower(transfer.to_email) <> lower(coalesce(auth.jwt()->>'email', ''))
  ) then
    raise exception 'Transfer is not available';
  end if;

  delete from public.pet_owners
  where pet_id = transfer.pet_id and user_id = transfer.from_user_id;

  insert into public.pet_owners (
    pet_id, user_id, relationship, relationship_type, is_primary
  ) values (
    transfer.pet_id, auth.uid(), 'primary_owner', 'primary_owner', true
  ) on conflict (pet_id, user_id) do update set
    relationship = 'primary_owner',
    relationship_type = 'primary_owner',
    is_primary = true;

  update public.pet_transfers set
    to_user_id = auth.uid(), status = 'accepted', responded_at = now()
  where id = transfer.id;
end;
$$;

create or replace function public.decline_pet_transfer(transfer_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  transfer public.pet_transfers;
begin
  select * into transfer from public.pet_transfers
  where id = transfer_id for update;

  if transfer.id is null or transfer.status <> 'pending' then
    raise exception 'Transfer is not available';
  end if;
  if auth.uid() is null or (
    transfer.to_user_id is distinct from auth.uid()
    and lower(transfer.to_email) <> lower(coalesce(auth.jwt()->>'email', ''))
  ) then
    raise exception 'Transfer is not available';
  end if;

  update public.pet_transfers set status = 'declined', responded_at = now()
  where id = transfer.id;
end;
$$;

revoke all on function public.accept_pet_transfer(uuid) from public;
revoke all on function public.decline_pet_transfer(uuid) from public;
grant execute on function public.accept_pet_transfer(uuid) to authenticated;
grant execute on function public.decline_pet_transfer(uuid) to authenticated;

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  constraint account_deletion_requests_status_check
    check (status in ('pending', 'processing', 'completed', 'rejected'))
);

create unique index if not exists account_deletion_one_active_request_idx
  on public.account_deletion_requests(user_id)
  where status in ('pending', 'processing');

alter table public.account_deletion_requests enable row level security;

drop policy if exists "users create own deletion request" on public.account_deletion_requests;
create policy "users create own deletion request"
on public.account_deletion_requests for insert to authenticated
with check (user_id = auth.uid() and status = 'pending');

drop policy if exists "users read own deletion request" on public.account_deletion_requests;
create policy "users read own deletion request"
on public.account_deletion_requests for select to authenticated
using (user_id = auth.uid());
