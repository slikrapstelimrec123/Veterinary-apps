-- Removes only the 15 deterministic demo pets created by
-- seed_15_pets_nagornyi.sql for nagornyi1103@icloud.com.
-- The transaction is intentionally owner-scoped and does not touch the
-- account's original pets or the screenshot-demo pet.
begin;

do $$
declare
  target_user_id uuid;
  removed_count integer;
begin
  select id
    into target_user_id
    from auth.users
   where lower(email) = 'nagornyi1103@icloud.com'
   limit 1;

  if target_user_id is null then
    raise exception 'USER_NOT_FOUND: nagornyi1103@icloud.com';
  end if;

  delete from public.pets pet
   where pet.owner_id = target_user_id
     and pet.id in (
       select ('78000000-0000-4000-8000-' || lpad(number::text, 12, '0'))::uuid
         from generate_series(1, 15) as numbers(number)
     );

  get diagnostics removed_count = row_count;
  raise notice 'Removed % deterministic demo pets for %',
    removed_count, 'nagornyi1103@icloud.com';
end $$;

commit;
