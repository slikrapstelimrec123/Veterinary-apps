# PostgreSQL Database Schema

Backend: Supabase PostgreSQL with Auth, Storage, and Row Level Security.

The implemented MVP schema lives in:

- `supabase/migrations/20260629150000_initial_mvp_schema.sql`
- `supabase/migrations/20260629151000_rls_policies.sql`
- `supabase/migrations/20260629153000_clinic_management_module.sql`

## profiles

Connected to `auth.users`.

Fields:

- `id uuid primary key references auth.users(id)`
- `email text not null`
- `full_name text not null`
- `phone text nullable`
- `avatar_url text nullable`
- `role text not null`
- `created_at timestamptz`
- `updated_at timestamptz`

Allowed roles:

- `pet_owner`
- `clinic_owner`
- `veterinarian`
- `clinic_manager`
- `platform_admin`

Access:

- Users can read and update their own profile.
- Platform admins can read profiles.
- Clinic members can read profiles connected to their clinic where needed.

## clinics

Clinic workspace and public profile.

Fields:

- `id uuid primary key`
- `name text not null`
- `legal_name text nullable`
- `description text nullable`
- `phone text nullable`
- `email text nullable`
- `website text nullable`
- `city text nullable`
- `country text nullable`
- `address text nullable`
- `latitude numeric nullable`
- `longitude numeric nullable`
- `logo_url text nullable`
- `cover_image_url text nullable`
- `working_hours jsonb nullable`
- `status text not null`
- `published boolean not null`
- `created_by uuid references profiles(id)`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz nullable`

Allowed statuses:

- `draft`
- `pending_verification`
- `published`
- `suspended`

Access:

- Public users can read published clinics.
- Clinic members can read their clinic.
- Clinic owners and clinic managers can update their clinic profile.
- Platform admins can read and update all clinics.

## clinic_members

Connects users to clinics.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `user_id uuid references profiles(id)`
- `role text not null`
- `status text not null`
- `invited_by uuid references profiles(id) nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

Allowed roles:

- `clinic_owner`
- `veterinarian`
- `clinic_manager`

Allowed statuses:

- `active`
- `invited`
- `suspended`
- `removed`

Access:

- Clinic owners can manage members of their clinic.
- Clinic members can read active members of their clinic.
- Platform admins can read and update all.

## doctors

Doctor profile inside a clinic.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `profile_id uuid references profiles(id) nullable`
- `full_name text not null`
- `specialization text nullable`
- `bio text nullable`
- `experience_years integer nullable`
- `avatar_url text nullable`
- `phone text nullable`
- `email text nullable`
- `status text not null`
- `is_public boolean not null`
- `default_appointment_duration_minutes integer`
- `schedule jsonb nullable`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz nullable`

Access:

- Public users can read active public doctors of published clinics.
- Clinic owners and managers can manage doctors.
- Veterinarians can read their linked doctor profile and clinic data allowed by RLS.
- Platform admins can read and update all.

## services

Clinic services and prices.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `name text not null`
- `category text nullable`
- `description text nullable`
- `duration_minutes integer`
- `price_amount numeric nullable`
- `price_currency text`
- `is_price_from boolean`
- `is_public boolean not null`
- `status text`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz nullable`

Access:

- Public users can read active public services of published clinics.
- Clinic owners and managers can manage services.

## doctor_schedules

Doctor availability prepared for future appointment booking.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id)`
- `day_of_week integer`
- `start_time time`
- `end_time time`
- `break_start_time time nullable`
- `break_end_time time nullable`
- `slot_duration_minutes integer`
- `is_active boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

Rules:

- `day_of_week` is `1` Monday through `7` Sunday.
- `start_time` must be before `end_time`.
- Break time must be inside working hours.
- Only one active schedule row per doctor and day is allowed.

Access:

- Clinic members can read schedules for their clinic.
- Clinic owners and clinic managers can manage schedules.
- Veterinarians can read their own linked schedule.
- Public schedule access remains closed until appointment booking is implemented.

## pets

Pet health card foundation.

Fields:

- `id uuid primary key`
- `name text not null`
- `species text not null`
- `breed text nullable`
- `sex text nullable`
- `birth_date date nullable`
- `approximate_age text nullable`
- `weight_kg numeric nullable`
- `photo_url text nullable`
- `color text nullable`
- `microchip_number text nullable`
- `avatar_url text nullable`
- `notes text nullable`
- `allergies text nullable`
- `chronic_conditions text nullable`
- `health_notes text nullable`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz nullable`

Access:

- Pet owners can read and update only their own pets.
- Clinic members can read pets connected to their appointments or visit records.
- Platform admins can read all when needed for support.

## pet_owners

Links pet owner profiles to pets.

Fields:

- `id uuid primary key`
- `pet_id uuid references pets(id)`
- `user_id uuid references profiles(id)`
- `relationship text`
- `relationship_type text`
- `is_primary boolean`
- `created_at timestamptz`

Access:

- Pet owners can read and create own ownership rows.

## appointments

Booking between owner, pet, clinic, doctor, and service.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id)`
- `service_id uuid references services(id)`
- `pet_id uuid references pets(id)`
- `owner_id uuid references profiles(id)`
- `starts_at timestamptz`
- `ends_at timestamptz`
- `status text`
- `price_amount numeric nullable`
- `price_currency text`
- `owner_comment text nullable`
- `clinic_comment text nullable`
- `cancelled_by uuid references profiles(id) nullable`
- `cancelled_at timestamptz nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

Access:

- Pet owners can create appointments for their own pets.
- Pet owners can read their own appointments.
- Clinic members can read and manage appointments for their clinic.
- Veterinarians can read appointments assigned to them.

## visit_records

Medical record created by a clinic or veterinarian.

Fields:

- `id uuid primary key`
- `appointment_id uuid references appointments(id) nullable`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id) nullable`
- `pet_id uuid references pets(id)`
- `created_by uuid references profiles(id)`
- `visit_date timestamptz`
- `reason text nullable`
- `diagnosis text nullable`
- `treatment_notes text nullable`
- `recommendations text nullable`
- `internal_notes text nullable`
- `follow_up_at timestamptz nullable`
- `status text`
- `created_at timestamptz`
- `updated_at timestamptz`

Access:

- Clinic members can create and update records for their clinic.
- Veterinarians can create records for assigned or clinic-connected appointments.
- Pet owners can read completed records for their own pets.
- Internal notes are clinic-only in UI.

## visit_documents

Private file metadata for visit records.

Fields:

- `id uuid primary key`
- `visit_record_id uuid references visit_records(id)`
- `clinic_id uuid references clinics(id)`
- `pet_id uuid references pets(id)`
- `uploaded_by uuid references profiles(id)`
- `document_type text`
- `title text nullable`
- `storage_bucket text`
- `storage_path text`
- `mime_type text nullable`
- `file_size_bytes bigint nullable`
- `is_visible_to_owner boolean`
- `created_at timestamptz`

Access:

- Same access logic as visit records.
- Files must stay in private Supabase Storage.
- Signed URLs should be generated only after access checks.

## reviews

Future public feedback after completed appointments.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id) nullable`
- `appointment_id uuid references appointments(id)`
- `owner_id uuid references profiles(id)`
- `rating integer`
- `comment text nullable`
- `is_published boolean`
- `created_at timestamptz`

MVP note:

- Table exists for expansion, but marketplace-style review features are not part of the current stage.

## subscriptions

Prepared future clinic monetization state.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `plan text`
- `status text`
- `provider text nullable`
- `provider_customer_id text nullable`
- `provider_subscription_id text nullable`
- `current_period_start timestamptz nullable`
- `current_period_end timestamptz nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

MVP note:

- Payments are not implemented yet.

## Helper Functions

Implemented in the RLS migration:

- `is_platform_admin()`
- `is_clinic_member(target_clinic_id uuid)`
- `has_clinic_role(target_clinic_id uuid, allowed_roles text[])`
- `owns_pet(target_pet_id uuid)`
- `can_access_visit_record(target_visit_record_id uuid)`
