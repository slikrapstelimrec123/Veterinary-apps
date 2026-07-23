-- App Store compliant self-service account deletion.
-- The Edge Function authenticates the caller, removes private Storage objects,
-- invokes this service-role-only cleanup, and finally deletes auth.users.

create or replace function public.delete_user_account_data(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_role text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required';
  end if;

  select role
    into target_role
  from public.profiles
  where id = target_user_id
  for update;

  if target_role = 'platform_admin' then
    raise exception 'Platform administrator accounts cannot be deleted here';
  end if;

  update public.clinics set created_by = null
  where created_by = target_user_id;
  update public.clinic_members set invited_by = null
  where invited_by = target_user_id;
  update public.doctors set profile_id = null
  where profile_id = target_user_id;
  update public.appointments set cancelled_by = null
  where cancelled_by = target_user_id;
  delete from public.subscription_upgrade_requests
  where requested_by = target_user_id;

  delete from public.visit_documents
  where uploaded_by = target_user_id
     or pet_id in (
       select id from public.pets where owner_id = target_user_id
       union
       select pet_id from public.pet_owners where user_id = target_user_id
     );

  delete from public.visit_records
  where created_by = target_user_id
     or owner_id = target_user_id
     or pet_id in (
       select id from public.pets where owner_id = target_user_id
       union
       select pet_id from public.pet_owners where user_id = target_user_id
     );

  delete from public.reviews
  where owner_id = target_user_id
     or pet_id in (
       select id from public.pets where owner_id = target_user_id
       union
       select pet_id from public.pet_owners where user_id = target_user_id
     );

  delete from public.appointments
  where owner_id = target_user_id
     or pet_id in (
       select id from public.pets where owner_id = target_user_id
       union
       select pet_id from public.pet_owners where user_id = target_user_id
     );

  delete from public.pet_transfers
  where from_user_id = target_user_id
     or to_user_id = target_user_id;

  delete from public.pet_owners
  where user_id = target_user_id;

  delete from public.pets
  where owner_id = target_user_id;

  delete from public.profiles
  where id = target_user_id;
end;
$$;

revoke all on function public.delete_user_account_data(uuid)
  from public, anon, authenticated;
grant execute on function public.delete_user_account_data(uuid)
  to service_role;

notify pgrst, 'reload schema';
