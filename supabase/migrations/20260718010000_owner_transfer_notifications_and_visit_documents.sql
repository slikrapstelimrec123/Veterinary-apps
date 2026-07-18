-- Owner-only reliability fixes for pet transfers, notifications, and
-- self-reported visit attachments.

create or replace function public.accept_pet_transfer(transfer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  transfer_record public.pet_transfers%rowtype;
begin
  if auth.uid() is null then
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
       transfer_record.to_user_id is distinct from auth.uid()
       and lower(transfer_record.to_email) <>
         lower(coalesce(auth.jwt()->>'email', ''))
     ) then
    raise exception 'Transfer is not available';
  end if;

  update public.pets
  set owner_id = auth.uid(),
      updated_at = now()
  where id = transfer_record.pet_id
    and owner_id = transfer_record.from_user_id;

  if not found then
    raise exception 'Pet ownership has changed';
  end if;

  -- A completed transfer replaces access to the private medical card.
  delete from public.pet_owners
  where pet_id = transfer_record.pet_id;

  insert into public.pet_owners (
    pet_id, user_id, relationship, relationship_type, is_primary
  ) values (
    transfer_record.pet_id, auth.uid(),
    'primary_owner', 'primary_owner', true
  )
  on conflict (pet_id, user_id) do update set
    relationship = excluded.relationship,
    relationship_type = excluded.relationship_type,
    is_primary = excluded.is_primary;

  update public.visit_records
  set owner_id = auth.uid(),
      updated_at = now()
  where pet_id = transfer_record.pet_id;

  update public.announcements
  set status = 'inactive',
      updated_at = now()
  where pet_id = transfer_record.pet_id
    and owner_id = transfer_record.from_user_id
    and status = 'active';

  update public.pet_transfers
  set to_user_id = auth.uid(),
      status = 'accepted',
      responded_at = now(),
      updated_at = now()
  where id = transfer_record.id;

  update public.notifications
  set status = 'read',
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where user_id = auth.uid()
    and type = 'pet_transfer_request'
    and data->>'transfer_id' = transfer_record.id::text;

  update public.notifications
  set status = 'archived',
      updated_at = now()
  where user_id = transfer_record.from_user_id
    and pet_id = transfer_record.pet_id
    and status <> 'archived';
end;
$$;

revoke all on function public.accept_pet_transfer(uuid) from public, anon;
grant execute on function public.accept_pet_transfer(uuid) to authenticated;

create or replace function public.mark_notification_read(
  target_notification_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_count integer;
begin
  update public.notifications
  set status = 'read',
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where id = target_notification_id
    and user_id = auth.uid()
    and status = 'unread';

  get diagnostics changed_count = row_count;
  return changed_count;
end;
$$;

create or replace function public.mark_all_notifications_read()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_count integer;
begin
  update public.notifications
  set status = 'read',
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where user_id = auth.uid()
    and status = 'unread';

  get diagnostics changed_count = row_count;
  return changed_count;
end;
$$;

revoke all on function public.mark_notification_read(uuid)
  from public, anon;
revoke all on function public.mark_all_notifications_read()
  from public, anon;
grant execute on function public.mark_notification_read(uuid)
  to authenticated;
grant execute on function public.mark_all_notifications_read()
  to authenticated;

alter table public.visit_documents
  alter column clinic_id drop not null;

drop policy if exists "owners read own visit documents"
  on public.visit_documents;
create policy "owners read own visit documents"
on public.visit_documents for select to authenticated
using (
  public.current_user_owns_pet(pet_id)
  and public.can_access_visit_record(visit_record_id)
);

drop policy if exists "owners create own visit documents"
  on public.visit_documents;
create policy "owners create own visit documents"
on public.visit_documents for insert to authenticated
with check (
  uploaded_by = auth.uid()
  and clinic_id is null
  and is_visible_to_owner is true
  and public.current_user_owns_pet(pet_id)
  and exists (
    select 1
    from public.visit_records visit
    where visit.id = visit_record_id
      and visit.pet_id = visit_documents.pet_id
      and visit.owner_id = auth.uid()
      and visit.status = 'self_reported'
  )
);

drop policy if exists "owners delete own visit documents"
  on public.visit_documents;
create policy "owners delete own visit documents"
on public.visit_documents for delete to authenticated
using (
  uploaded_by = auth.uid()
  and public.current_user_owns_pet(pet_id)
);

grant select, insert, delete on public.visit_documents to authenticated;

drop policy if exists "owners upload own visit documents"
  on storage.objects;
create policy "owners upload own visit documents"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'visit-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_user_owns_pet(
    ((storage.foldername(name))[2])::uuid
  )
);

drop policy if exists "owners read own visit document files"
  on storage.objects;
create policy "owners read own visit document files"
on storage.objects for select to authenticated
using (
  bucket_id = 'visit-documents'
  and exists (
    select 1
    from public.visit_documents document
    where document.storage_bucket = bucket_id
      and document.storage_path = name
      and public.current_user_owns_pet(document.pet_id)
  )
);

drop policy if exists "owners delete own visit document files"
  on storage.objects;
create policy "owners delete own visit document files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'visit-documents'
  and exists (
    select 1
    from public.visit_documents document
    where document.storage_bucket = bucket_id
      and document.storage_path = name
      and document.uploaded_by = auth.uid()
      and public.current_user_owns_pet(document.pet_id)
  )
);

-- A transferred medical record remains editable by the current owner while
-- preserving the original creator for audit history.
drop policy if exists "owners update self reported visit records"
  on public.visit_records;
create policy "owners update self reported visit records"
on public.visit_records for update to authenticated
using (
  owner_id = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and status = 'self_reported'
)
with check (
  owner_id = auth.uid()
  and public.current_user_owns_pet(pet_id)
  and clinic_id is null
  and doctor_id is null
  and appointment_id is null
  and status = 'self_reported'
  and internal_notes is null
);
