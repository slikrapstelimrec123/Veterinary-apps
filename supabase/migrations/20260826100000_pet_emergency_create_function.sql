-- Persist emergency fields when a pet is created through the owner RPC.
create or replace function public.create_pet_for_current_user(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  created_pet public.pets;
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;
  if nullif(trim(payload->>'name'), '') is null
     or nullif(trim(payload->>'species'), '') is null then
    raise exception 'Pet name and species are required';
  end if;
  insert into public.pets (
    owner_id, name, species, breed, sex, birth_date, weight_kg, color,
    microchip_number, avatar_url, avatar_storage_path, notes, is_neutered,
    passport_photo_url, passport_storage_path, emergency_allergies,
    emergency_conditions, emergency_surgeries, emergency_contraindications,
    emergency_behavior_notes, emergency_blood_type, emergency_notes
  ) values (
    current_user_id, trim(payload->>'name'), trim(payload->>'species'),
    nullif(trim(payload->>'breed'), ''), nullif(trim(payload->>'sex'), ''),
    nullif(payload->>'birth_date', '')::date, nullif(payload->>'weight_kg', '')::numeric,
    nullif(trim(payload->>'color'), ''), nullif(trim(payload->>'microchip_number'), ''),
    nullif(trim(payload->>'avatar_url'), ''), nullif(trim(payload->>'avatar_storage_path'), ''),
    nullif(trim(payload->>'notes'), ''), nullif(payload->>'is_neutered', '')::boolean,
    nullif(trim(payload->>'passport_photo_url'), ''), nullif(trim(payload->>'passport_storage_path'), ''),
    nullif(trim(payload->>'emergency_allergies'), ''), nullif(trim(payload->>'emergency_conditions'), ''),
    nullif(trim(payload->>'emergency_surgeries'), ''), nullif(trim(payload->>'emergency_contraindications'), ''),
    nullif(trim(payload->>'emergency_behavior_notes'), ''), nullif(trim(payload->>'emergency_blood_type'), ''),
    nullif(trim(payload->>'emergency_notes'), '')
  ) returning * into created_pet;
  insert into public.pet_owners (pet_id, user_id, relationship, relationship_type, is_primary)
  values (created_pet.id, current_user_id, 'primary_owner', 'primary_owner', true)
  on conflict (pet_id, user_id) do update set is_primary = true;
  return to_jsonb(created_pet);
end;
$$;

revoke all on function public.create_pet_for_current_user(jsonb) from public, anon;
grant execute on function public.create_pet_for_current_user(jsonb) to authenticated;
