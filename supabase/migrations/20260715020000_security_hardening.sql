-- Security hardening for the TestFlight beta.
-- Removes legacy permissive policies, protects profile roles, and restores
-- clinic-only control over medical records and private documents.

-- A signed-in user may edit only public profile fields. Role and identity
-- fields remain writable by trusted backend roles (postgres/service_role).
alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

-- Bring early mobile-beta tables up to the repository schema before applying
-- policies. Existing values are copied from the legacy column names.
alter table public.visit_records
  add column if not exists created_by uuid references public.profiles(id),
  add column if not exists reason_for_visit text,
  add column if not exists procedures_performed text,
  add column if not exists treatment_notes text,
  add column if not exists prescribed_medications text,
  add column if not exists internal_notes text,
  add column if not exists follow_up_at timestamptz,
  add column if not exists next_visit_recommended boolean not null default false,
  add column if not exists updated_at timestamptz not null default now();

update public.visit_records
set reason_for_visit = coalesce(reason_for_visit, reason),
    next_visit_recommended = coalesce(next_visit_recommended, next_visit_date is not null)
where reason_for_visit is null or next_visit_recommended = false;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'visit_records'
      and column_name = 'treatment'
  ) then
    execute 'update public.visit_records
             set treatment_notes = coalesce(treatment_notes, treatment)
             where treatment_notes is null';
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'visit_records'
      and column_name = 'medications_given'
  ) then
    execute 'update public.visit_records
             set prescribed_medications = coalesce(prescribed_medications, medications_given)
             where prescribed_medications is null';
  end if;
end;
$$;

alter table public.visit_documents
  add column if not exists clinic_id uuid references public.clinics(id),
  add column if not exists uploaded_by uuid references public.profiles(id),
  add column if not exists mime_type text,
  add column if not exists file_size_bytes bigint,
  add column if not exists updated_at timestamptz not null default now();

update public.visit_documents
set mime_type = coalesce(mime_type, file_type),
    file_size_bytes = coalesce(file_size_bytes, file_size::bigint)
where mime_type is null or file_size_bytes is null;

revoke update on table public.profiles from anon, authenticated;
grant update (full_name, phone, city, updated_at)
  on table public.profiles to authenticated;

drop policy if exists "Users update own profile" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
drop policy if exists "users update own safe profile fields" on public.profiles;
create policy "users update own safe profile fields"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Remove policies that accidentally granted every authenticated user access
-- to every pet event, feeding and visit document.
drop policy if exists "authenticated" on public.pet_achievements;
drop policy if exists "authenticated" on public.pet_feedings;
drop policy if exists "authenticated" on public.visit_documents;

drop policy if exists "owners manage pet achievements" on public.pet_achievements;
create policy "owners manage pet achievements"
on public.pet_achievements for all to authenticated
using (public.owns_pet(pet_id))
with check (public.owns_pet(pet_id));

drop policy if exists "owners manage pet feedings" on public.pet_feedings;
create policy "owners manage pet feedings"
on public.pet_feedings for all to authenticated
using (public.owns_pet(pet_id))
with check (public.owns_pet(pet_id));

-- Medical records are created and changed only by connected clinic staff.
-- Owners can read only published records for pets they own.
drop policy if exists "Owners can insert visit records" on public.visit_records;
drop policy if exists "Owners can select their visit records" on public.visit_records;
drop policy if exists "Users manage own visit records" on public.visit_records;
drop policy if exists "owners and clinic members read visit records" on public.visit_records;
drop policy if exists "clinic medical staff create visit records" on public.visit_records;
drop policy if exists "clinic members update clinic visit records" on public.visit_records;
drop policy if exists "owners and clinic staff read visit records" on public.visit_records;
drop policy if exists "clinic staff create visit records" on public.visit_records;
drop policy if exists "clinic staff update visit records" on public.visit_records;

create or replace function public.can_access_visit_record(target_visit_record_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.visit_records
    where id = target_visit_record_id
      and (
        public.is_platform_admin()
        or public.is_clinic_member(clinic_id)
        or (status = 'published' and public.owns_pet(pet_id))
      )
  );
$$;

create policy "owners and clinic staff read visit records"
on public.visit_records for select to authenticated
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (status = 'published' and public.owns_pet(pet_id))
);

create policy "clinic staff create visit records"
on public.visit_records for insert to authenticated
with check (
  (
    public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
    or public.is_platform_admin()
    or exists (
      select 1
      from public.doctors
      where doctors.id = visit_records.doctor_id
        and doctors.profile_id = auth.uid()
        and doctors.clinic_id = visit_records.clinic_id
    )
  )
  and (
    appointment_id is null
    or exists (
      select 1
      from public.appointments
      where appointments.id = visit_records.appointment_id
        and appointments.clinic_id = visit_records.clinic_id
        and appointments.pet_id = visit_records.pet_id
        and (
          public.has_clinic_role(visit_records.clinic_id, array['clinic_owner', 'clinic_manager'])
          or public.is_platform_admin()
          or exists (
            select 1
            from public.doctors
            where doctors.id = appointments.doctor_id
              and doctors.profile_id = auth.uid()
          )
        )
    )
  )
);

create policy "clinic staff update visit records"
on public.visit_records for update to authenticated
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or created_by = auth.uid()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or created_by = auth.uid()
);

-- Do not expose internal clinic notes through the owner-facing REST table.
-- Clinic software can access them through a separately authorized backend flow.
revoke select on table public.visit_records from anon, authenticated;
grant select (
  id, appointment_id, clinic_id, doctor_id, pet_id, created_by, visit_date,
  reason, diagnosis, treatment_notes, recommendations, follow_up_at, status,
  created_at, updated_at, owner_id, reason_for_visit, symptoms,
  procedures_performed, prescribed_medications, next_visit_recommended,
  next_visit_date
) on table public.visit_records to authenticated;

drop policy if exists "Users see own pet documents" on public.visit_documents;
drop policy if exists "owners and clinic members read visit documents" on public.visit_documents;
drop policy if exists "clinic members create visit documents" on public.visit_documents;
drop policy if exists "clinic members update visit documents" on public.visit_documents;
drop policy if exists "owners and clinic staff read visit documents" on public.visit_documents;
drop policy if exists "clinic staff create visit documents" on public.visit_documents;
drop policy if exists "clinic staff update visit documents" on public.visit_documents;
drop policy if exists "clinic staff delete visit documents" on public.visit_documents;

create or replace function public.can_read_visit_document(target_document_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.visit_documents
    join public.visit_records
      on visit_records.id = visit_documents.visit_record_id
    where visit_documents.id = target_document_id
      and (
        public.is_platform_admin()
        or public.is_clinic_member(visit_documents.clinic_id)
        or (
          visit_documents.is_visible_to_owner = true
          and visit_records.status = 'published'
          and public.owns_pet(visit_documents.pet_id)
        )
      )
  );
$$;

create policy "owners and clinic staff read visit documents"
on public.visit_documents for select to authenticated
using (public.can_read_visit_document(id));

create policy "clinic staff create visit documents"
on public.visit_documents for insert to authenticated
with check (
  public.is_clinic_member(clinic_id)
  and public.can_access_visit_record(visit_record_id)
);

create policy "clinic staff update visit documents"
on public.visit_documents for update to authenticated
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or uploaded_by = auth.uid()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or uploaded_by = auth.uid()
);

create policy "clinic staff delete visit documents"
on public.visit_documents for delete to authenticated
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or uploaded_by = auth.uid()
);

-- Medical and achievement files are private. Access is always mediated by RLS
-- and short-lived signed URLs.
update storage.buckets
set public = false
where id in ('achievement-photos', 'visit-documents');

drop policy if exists "clinic staff upload visit documents" on storage.objects;
drop policy if exists "authorized users read visit documents" on storage.objects;
drop policy if exists "clinic staff update visit documents" on storage.objects;
drop policy if exists "clinic staff delete visit documents" on storage.objects;

create policy "clinic staff upload visit documents"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
);

create policy "authorized users read visit documents"
on storage.objects for select to authenticated
using (
  bucket_id = 'visit-documents'
  and (
    public.is_clinic_member((storage.foldername(name))[1]::uuid)
    or public.is_platform_admin()
    or exists (
      select 1
      from public.visit_documents
      join public.visit_records
        on visit_records.id = visit_documents.visit_record_id
      where visit_documents.storage_path = storage.objects.name
        and visit_documents.is_visible_to_owner = true
        and visit_records.status = 'published'
        and public.owns_pet(visit_documents.pet_id)
    )
  )
);

create policy "clinic staff update visit documents"
on storage.objects for update to authenticated
using (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
);

create policy "clinic staff delete visit documents"
on storage.objects for delete to authenticated
using (
  bucket_id = 'visit-documents'
  and public.has_clinic_role(
    (storage.foldername(name))[1]::uuid,
    array['clinic_owner', 'clinic_manager']
  )
);

-- Use fixed search paths and expose callable functions only to roles that need
-- them. Trigger functions must never be directly callable by API clients.
alter function public.set_updated_at() set search_path = pg_catalog, public;
alter function public.pet_id_from_storage_path(text)
  set search_path = pg_catalog, public, storage;

revoke execute on function public.accept_pet_transfer(uuid) from public, anon;
revoke execute on function public.decline_pet_transfer(uuid) from public, anon;
grant execute on function public.accept_pet_transfer(uuid) to authenticated;
grant execute on function public.decline_pet_transfer(uuid) to authenticated;

revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
revoke execute on function public.resolve_pet_transfer_recipient() from public, anon, authenticated;
revoke execute on function public.notify_pet_transfer_recipient() from public, anon, authenticated;

do $$
begin
  if to_regprocedure('public.handle_new_user()') is not null then
    execute 'revoke execute on function public.handle_new_user() from public, anon, authenticated';
  end if;
end;
$$;

revoke execute on function public.is_platform_admin() from public, anon;
revoke execute on function public.is_clinic_member(uuid) from public, anon;
revoke execute on function public.has_clinic_role(uuid, text[]) from public, anon;
revoke execute on function public.owns_pet(uuid) from public, anon;
revoke execute on function public.can_access_visit_record(uuid) from public, anon;
revoke execute on function public.can_read_visit_document(uuid) from public, anon;

grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.is_clinic_member(uuid) to authenticated;
grant execute on function public.has_clinic_role(uuid, text[]) to authenticated;
grant execute on function public.owns_pet(uuid) to authenticated;
grant execute on function public.can_access_visit_record(uuid) to authenticated;
grant execute on function public.can_read_visit_document(uuid) to authenticated;
