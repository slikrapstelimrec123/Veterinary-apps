-- Pet owner mobile module RLS reference.
-- Applied migration: supabase/migrations/20260629154500_pet_owner_mobile_module.sql

-- pets:
-- - pet_owner can create pets
-- - pet_owner can read/update only pets linked through pet_owners
-- - clinic members can read pets only through clinic appointments or visit records
-- - platform_admin can read all if needed for support

-- pet_owners:
-- - pet_owner can create and read links for their own profile
-- - clinic access remains indirect through clinic-connected appointments/records

-- visit_records:
-- - pet_owner reads only published records for owned pets
-- - pet_owner cannot create or update clinic records

-- visit_documents:
-- - pet_owner reads only visible metadata for owned pets and accessible visit records
-- - private file URLs must not be exposed publicly
