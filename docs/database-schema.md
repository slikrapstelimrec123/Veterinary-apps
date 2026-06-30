# PostgreSQL Database Schema

Backend: Supabase PostgreSQL with Auth, Storage, and Row Level Security.

The implemented MVP schema lives in:

- `supabase/migrations/20260629150000_initial_mvp_schema.sql`
- `supabase/migrations/20260629151000_rls_policies.sql`
- `supabase/migrations/20260629153000_clinic_management_module.sql`
- `supabase/migrations/20260630143000_appointment_booking_module.sql`
- `supabase/migrations/20260630160000_visit_records_documents_module.sql`
- `supabase/migrations/20260630183000_reviews_ratings_module.sql`
- `supabase/migrations/20260630200000_clinic_subscriptions_module.sql`

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
- Public users can read active schedule rows only for active public doctors in published clinics so the mobile app can calculate available booking slots.

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
- `appointment_date date`
- `start_time time`
- `end_time time`
- `status text`
- `price_amount numeric nullable`
- `price_currency text`
- `owner_comment text nullable`
- `clinic_comment text nullable`
- `owner_note text nullable`
- `clinic_note text nullable`
- `cancellation_reason text nullable`
- `cancelled_by uuid references profiles(id) nullable`
- `cancelled_at timestamptz nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

Access:

- Pet owners can create pending appointments for their own pets in published clinics using active public services and doctors.
- Pet owners can read their own appointments.
- Pet owners can cancel their own pending or confirmed appointments.
- Clinic owners and managers can read appointments for their clinic.
- Clinic owners and managers can confirm, cancel, complete, mark no-show, add clinic notes, and assign doctors.
- Veterinarians can read appointments assigned to them.

## visit_records

Medical record created by a clinic or veterinarian.

Fields:

- `id uuid primary key`
- `appointment_id uuid references appointments(id) nullable`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id) nullable`
- `pet_id uuid references pets(id)`
- `owner_id uuid references profiles(id) nullable`
- `created_by uuid references profiles(id)`
- `visit_date date`
- `reason_for_visit text nullable`
- `symptoms text nullable`
- `diagnosis text nullable`
- `procedures_performed text nullable`
- `treatment_notes text nullable`
- `prescribed_medications text nullable`
- `recommendations text nullable`
- `next_visit_recommended boolean`
- `next_visit_date date nullable`
- `internal_notes text nullable`
- `status text`
- `created_at timestamptz`
- `updated_at timestamptz`

Access:

- Clinic members can create and update records for their clinic.
- Veterinarians can create records for assigned or clinic-connected appointments.
- Pet owners can read only published records for their own pets.
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
- `file_name text nullable`
- `file_type text nullable`
- `file_size integer nullable`
- `storage_bucket text`
- `storage_path text`
- `mime_type text nullable`
- `file_size_bytes bigint nullable`
- `description text nullable`
- `is_visible_to_owner boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

Access:

- Same access logic as visit records.
- Files must stay in private Supabase Storage.
- Signed URLs should be generated only after access checks.
- Private bucket: `visit-documents`.
- Recommended storage path: `clinic_id/pet_id/visit_record_id/file_name`.

## reviews

Post-appointment feedback from pet owners after completed appointments or published visit records.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `doctor_id uuid references doctors(id) nullable`
- `appointment_id uuid references appointments(id)`
- `visit_record_id uuid references visit_records(id) nullable`
- `pet_id uuid references pets(id)`
- `owner_id uuid references profiles(id)`
- `rating integer`
- `doctor_rating integer nullable`
- `clinic_rating integer nullable`
- `service_quality_rating integer nullable`
- `comment text nullable`
- `is_published boolean`
- `status text`
- `is_anonymous boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

Constraints and helpers:

- `rating`, `doctor_rating`, `clinic_rating`, and `service_quality_rating` are limited to 1-5.
- Unique review per `appointment_id` + `owner_id`.
- Trigger validates owner, clinic, doctor, pet, appointment, and visit record relationships.
- `can_user_review_appointment(user_id, appointment_id)` checks review eligibility.
- `has_user_reviewed_appointment(user_id, appointment_id)` prevents duplicate reviews.

Rating summaries:

- `clinic_rating_summary`: average rating, review count, average clinic rating, latest review date.
- `doctor_rating_summary`: average rating, review count, average doctor rating, latest review date.
- Summary views include only `published` reviews.

## subscription_plans

Configurable SaaS plans for clinics.

Fields:

- `id uuid primary key`
- `code text unique`
- `name text`
- `description text nullable`
- `price_monthly numeric nullable`
- `price_yearly numeric nullable`
- `currency text`
- `is_active boolean`
- `is_public boolean`
- `sort_order integer`
- `limits jsonb`
- `features jsonb`
- `created_at timestamptz`
- `updated_at timestamptz`

Seeded plans:

- `free`
- `basic`
- `pro`
- `enterprise`

## clinic_subscriptions

Current clinic plan state.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `plan_id uuid references subscription_plans(id)`
- `status text`
- `billing_period text nullable`
- `current_period_start timestamptz nullable`
- `current_period_end timestamptz nullable`
- `trial_ends_at timestamptz nullable`
- `cancel_at_period_end boolean`
- `external_provider text nullable`
- `external_subscription_id text nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

Allowed statuses:

- `trialing`
- `active`
- `past_due`
- `cancelled`
- `expired`
- `suspended`
- `manual`

## subscription_usage

Optional stored usage snapshot table. Current MVP calculates usage dynamically with helper functions.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `period_start timestamptz`
- `period_end timestamptz`
- `doctors_count integer`
- `services_count integer`
- `appointments_count integer`
- `visit_records_count integer`
- `documents_count integer`
- `storage_used_mb numeric`
- `created_at timestamptz`
- `updated_at timestamptz`

## subscription_upgrade_requests

Mock upgrade flow for MVP manual activation.

Fields:

- `id uuid primary key`
- `clinic_id uuid references clinics(id)`
- `requested_plan_id uuid references subscription_plans(id)`
- `requested_by uuid references profiles(id)`
- `status text`
- `note text nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

Allowed statuses:

- `pending`
- `approved`
- `rejected`
- `cancelled`

## Helper Functions

Implemented in the RLS migration:

- `is_platform_admin()`
- `is_clinic_member(target_clinic_id uuid)`
- `has_clinic_role(target_clinic_id uuid, allowed_roles text[])`
- `owns_pet(target_pet_id uuid)`
- `can_access_visit_record(target_visit_record_id uuid)`
- `get_clinic_active_subscription(target_clinic_id uuid)`
- `get_clinic_plan_limits(target_clinic_id uuid)`
- `get_clinic_usage(target_clinic_id uuid)`
- `can_clinic_add_doctor(target_clinic_id uuid)`
- `can_clinic_add_service(target_clinic_id uuid)`
- `can_clinic_create_appointment(target_clinic_id uuid)`
- `can_clinic_create_visit_record(target_clinic_id uuid)`
- `can_clinic_upload_document(target_clinic_id uuid, file_size_bytes bigint)`
- `can_clinic_publish_profile(target_clinic_id uuid)`
- `can_clinic_use_reviews(target_clinic_id uuid)`
