-- Restores owner-created visit records for both current and legacy pet rows.
-- Some production pets use pets.owner_id while older rows rely on pet_owners.

alter table public.visit_records
  add column if not exists provider_name text,
  alter column clinic_id drop not null,
  drop constraint if exists visit_records_status_check,
  add constraint visit_records_status_check
    check (status in ('draft', 'published', 'archived', 'self_reported'));

create or replace function public.current_user_owns_pet(target_pet_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.pets pet
    where pet.id = target_pet_id
      and pet.owner_id = auth.uid()
  )
  or exists (
    select 1
    from public.pet_owners ownership
    where ownership.pet_id = target_pet_id
      and ownership.user_id = auth.uid()
  );
$$;

revoke all on function public.current_user_owns_pet(uuid)
  from public, anon;
grant execute on function public.current_user_owns_pet(uuid)
  to authenticated;

drop policy if exists "owners create self reported visit records"
  on public.visit_records;
create policy "owners create self reported visit records"
on public.visit_records for insert to authenticated
with check (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and clinic_id is null
  and doctor_id is null
  and appointment_id is null
  and status = 'self_reported'
  and internal_notes is null
);

drop policy if exists "owners read own visit records"
  on public.visit_records;
create policy "owners read own visit records"
on public.visit_records for select to authenticated
using (
  public.is_platform_admin()
  or (
    status in ('published', 'self_reported')
    and public.current_user_owns_pet(pet_id)
  )
);

drop policy if exists "owners update self reported visit records"
  on public.visit_records;
create policy "owners update self reported visit records"
on public.visit_records for update to authenticated
using (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and status = 'self_reported'
)
with check (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and clinic_id is null
  and doctor_id is null
  and appointment_id is null
  and status = 'self_reported'
  and internal_notes is null
);

drop policy if exists "owners delete self reported visit records"
  on public.visit_records;
create policy "owners delete self reported visit records"
on public.visit_records for delete to authenticated
using (
  owner_id = auth.uid()
  and created_by = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and status = 'self_reported'
);

grant select, insert, update, delete on public.visit_records
  to authenticated;
