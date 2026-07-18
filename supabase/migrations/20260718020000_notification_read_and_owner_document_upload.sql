-- Repair notification read state and make owner visit-document registration
-- independent from legacy clinic policies.

alter table public.notifications
  add column if not exists read_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

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

create or replace function public.create_owner_visit_document(
  p_visit_record_id uuid,
  p_pet_id uuid,
  p_title text,
  p_document_type text,
  p_storage_path text,
  p_mime_type text,
  p_file_size bigint,
  p_file_name text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not public.current_user_owns_pet(p_pet_id) then
    raise exception 'Pet is unavailable';
  end if;

  if not exists (
    select 1
    from public.visit_records record
    where record.id = p_visit_record_id
      and record.pet_id = p_pet_id
      and record.owner_id = auth.uid()
      and record.status = 'self_reported'
  ) then
    raise exception 'Visit record is unavailable';
  end if;

  insert into public.visit_documents (
    visit_record_id,
    clinic_id,
    pet_id,
    uploaded_by,
    document_type,
    title,
    storage_bucket,
    storage_path,
    mime_type,
    file_size_bytes,
    file_name,
    file_type,
    file_size,
    is_visible_to_owner
  )
  values (
    p_visit_record_id,
    null,
    p_pet_id,
    auth.uid(),
    nullif(trim(p_document_type), ''),
    nullif(trim(p_title), ''),
    'visit-documents',
    p_storage_path,
    p_mime_type,
    p_file_size,
    nullif(trim(p_file_name), ''),
    p_mime_type,
    least(p_file_size, 2147483647)::integer,
    true
  )
  returning id into created_id;

  return created_id;
end;
$$;

revoke all on function public.create_owner_visit_document(
  uuid, uuid, text, text, text, text, bigint, text
) from public, anon;
grant execute on function public.create_owner_visit_document(
  uuid, uuid, text, text, text, text, bigint, text
) to authenticated;
