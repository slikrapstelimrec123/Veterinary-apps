-- Keep transfer acceptance compatible with the production pets table.
-- Some deployed projects do not expose pets.updated_at, so ownership changes
-- must not depend on that optional column.

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
  set owner_id = current_user_id
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
