alter table pets
  add column if not exists color text,
  add column if not exists microchip_number text,
  add column if not exists avatar_url text,
  add column if not exists notes text;

update pets
set avatar_url = coalesce(avatar_url, photo_url),
    notes = coalesce(notes, health_notes)
where avatar_url is null
   or notes is null;

alter table pet_owners
  add column if not exists relationship_type text not null default 'primary_owner',
  add column if not exists is_primary boolean not null default true;

update pet_owners
set relationship_type = relationship
where relationship_type is null
   or relationship_type = 'primary_owner';

create index if not exists pets_microchip_number_idx on pets(microchip_number);
create index if not exists visit_documents_pet_idx on visit_documents(pet_id);

drop policy if exists "pet owners create pets" on pets;
create policy "pet owners create pets"
on pets for insert
with check (
  exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'pet_owner'
  )
);

drop policy if exists "pet owners create own ownership" on pet_owners;
create policy "pet owners create own ownership"
on pet_owners for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'pet_owner'
  )
);

drop policy if exists "owners and clinic members read visit documents" on visit_documents;
create policy "owners and clinic members read visit documents"
on visit_documents for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (
    is_visible_to_owner = true
    and public.owns_pet(pet_id)
    and public.can_access_visit_record(visit_record_id)
  )
);

