-- Visit records and private medical documents module.
-- Keeps medical content private and exposes only published owner-safe records to pet owners.

alter table visit_records
  add column if not exists owner_id uuid references profiles(id),
  add column if not exists reason_for_visit text,
  add column if not exists symptoms text,
  add column if not exists procedures_performed text,
  add column if not exists prescribed_medications text,
  add column if not exists next_visit_recommended boolean not null default false,
  add column if not exists next_visit_date date;

update visit_records
set
  reason_for_visit = coalesce(reason_for_visit, reason),
  next_visit_date = coalesce(next_visit_date, follow_up_at::date),
  next_visit_recommended = coalesce(next_visit_recommended, follow_up_at is not null),
  status = case
    when status = 'completed' then 'published'
    else status
  end
where reason_for_visit is null
   or next_visit_date is null
   or status = 'completed';

update visit_records
set owner_id = pet_owners.user_id
from pet_owners
where visit_records.owner_id is null
  and pet_owners.pet_id = visit_records.pet_id
  and pet_owners.is_primary = true;

alter table visit_records
  alter column visit_date type date using visit_date::date,
  alter column visit_date set default current_date,
  alter column status set default 'draft',
  drop constraint if exists visit_records_status_check,
  add constraint visit_records_status_check check (status in ('draft', 'published', 'archived')),
  drop constraint if exists visit_records_publish_content_check,
  add constraint visit_records_publish_content_check check (
    status <> 'published'
    or diagnosis is not null
    or treatment_notes is not null
    or recommendations is not null
  ),
  drop constraint if exists visit_records_next_visit_check,
  add constraint visit_records_next_visit_check check (
    next_visit_recommended = false
    or next_visit_date is not null
  );

alter table visit_documents
  add column if not exists file_name text,
  add column if not exists file_type text,
  add column if not exists file_size integer,
  add column if not exists description text,
  add column if not exists updated_at timestamptz not null default now();

update visit_documents
set
  file_name = coalesce(file_name, title, split_part(storage_path, '/', array_length(string_to_array(storage_path, '/'), 1))),
  file_type = coalesce(file_type, mime_type),
  file_size = coalesce(file_size, file_size_bytes::integer),
  storage_bucket = coalesce(storage_bucket, 'visit-documents')
where file_name is null
   or file_type is null
   or file_size is null
   or storage_bucket is null;

update visit_documents
set document_type = 'other'
where document_type not in ('lab_result', 'certificate', 'prescription', 'xray', 'ultrasound', 'photo', 'vaccination_record', 'other');

alter table visit_documents
  alter column storage_bucket set default 'visit-documents',
  drop constraint if exists visit_documents_type_check,
  add constraint visit_documents_type_check check (
    document_type in ('lab_result', 'certificate', 'prescription', 'xray', 'ultrasound', 'photo', 'vaccination_record', 'other')
  );

create index if not exists visit_records_owner_idx on visit_records(owner_id);
create index if not exists visit_records_pet_status_idx on visit_records(pet_id, status);
create index if not exists visit_records_appointment_idx on visit_records(appointment_id);
create index if not exists visit_documents_visit_record_idx on visit_documents(visit_record_id);
create index if not exists visit_documents_pet_visible_idx on visit_documents(pet_id, is_visible_to_owner);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'visit-documents',
  'visit-documents',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/heic']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.can_access_visit_record(target_visit_record_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from visit_records
    where id = target_visit_record_id
      and (
        public.is_platform_admin()
        or public.is_clinic_member(clinic_id)
        or (status = 'published' and public.owns_pet(pet_id))
      )
  );
$$;

create or replace function public.can_read_visit_document(target_document_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from visit_documents
    join visit_records on visit_records.id = visit_documents.visit_record_id
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

drop policy if exists "owners and clinic members read visit records" on visit_records;
drop policy if exists "clinic medical staff create visit records" on visit_records;
drop policy if exists "clinic members update clinic visit records" on visit_records;
drop policy if exists "owners and clinic members read visit documents" on visit_documents;
drop policy if exists "clinic members create visit documents" on visit_documents;
drop policy if exists "clinic members update visit documents" on visit_documents;

create policy "owners and clinic staff read visit records"
on visit_records for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (status = 'published' and public.owns_pet(pet_id))
);

create policy "clinic staff create visit records"
on visit_records for insert
with check (
  (
    public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
    or public.is_platform_admin()
    or exists (
      select 1 from doctors
      where doctors.id = visit_records.doctor_id
        and doctors.profile_id = auth.uid()
        and doctors.clinic_id = visit_records.clinic_id
    )
  )
  and (
    appointment_id is null
    or exists (
      select 1 from appointments
      where appointments.id = visit_records.appointment_id
        and appointments.clinic_id = visit_records.clinic_id
        and appointments.pet_id = visit_records.pet_id
        and (
          public.has_clinic_role(visit_records.clinic_id, array['clinic_owner', 'clinic_manager'])
          or public.is_platform_admin()
          or exists (
            select 1 from doctors
            where doctors.id = appointments.doctor_id
              and doctors.profile_id = auth.uid()
          )
        )
    )
  )
);

create policy "clinic staff update visit records"
on visit_records for update
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

create policy "owners and clinic staff read visit documents"
on visit_documents for select
using (public.can_read_visit_document(id));

create policy "clinic staff create visit documents"
on visit_documents for insert
with check (
  public.is_clinic_member(clinic_id)
  and public.can_access_visit_record(visit_record_id)
);

create policy "clinic staff update visit documents"
on visit_documents for update
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

drop policy if exists "clinic staff upload visit documents" on storage.objects;
drop policy if exists "authorized users read visit documents" on storage.objects;
drop policy if exists "clinic staff update visit documents" on storage.objects;
drop policy if exists "clinic staff delete visit documents" on storage.objects;

create policy "clinic staff upload visit documents"
on storage.objects for insert
with check (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
);

create policy "authorized users read visit documents"
on storage.objects for select
using (
  bucket_id = 'visit-documents'
  and (
    public.is_clinic_member((storage.foldername(name))[1]::uuid)
    or public.is_platform_admin()
    or exists (
      select 1
      from visit_documents
      join visit_records on visit_records.id = visit_documents.visit_record_id
      where visit_documents.storage_path = storage.objects.name
        and visit_documents.is_visible_to_owner = true
        and visit_records.status = 'published'
        and public.owns_pet(visit_documents.pet_id)
    )
  )
);

create policy "clinic staff update visit documents"
on storage.objects for update
using (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'visit-documents'
  and public.is_clinic_member((storage.foldername(name))[1]::uuid)
);

create policy "clinic staff delete visit documents"
on storage.objects for delete
using (
  bucket_id = 'visit-documents'
  and public.has_clinic_role((storage.foldername(name))[1]::uuid, array['clinic_owner', 'clinic_manager'])
);
