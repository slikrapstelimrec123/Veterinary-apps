create extension if not exists "pgcrypto";

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  phone text,
  avatar_url text,
  role text not null default 'pet_owner',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_role_check check (
    role in ('pet_owner', 'clinic_owner', 'veterinarian', 'clinic_manager', 'platform_admin')
  )
);

create table clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  description text,
  phone text,
  email text,
  website text,
  city text,
  address text,
  latitude numeric,
  longitude numeric,
  logo_url text,
  cover_image_url text,
  working_hours jsonb,
  status text not null default 'draft',
  created_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint clinics_status_check check (status in ('draft', 'pending_verification', 'published', 'suspended'))
);

create table clinic_members (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null,
  status text not null default 'active',
  invited_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (clinic_id, user_id),
  constraint clinic_members_role_check check (role in ('clinic_owner', 'veterinarian', 'clinic_manager')),
  constraint clinic_members_status_check check (status in ('active', 'invited', 'suspended', 'removed'))
);

create table doctors (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  profile_id uuid references profiles(id),
  full_name text not null,
  specialization text,
  bio text,
  experience_years integer,
  avatar_url text,
  status text not null default 'draft',
  default_appointment_duration_minutes integer not null default 30,
  schedule jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint doctors_status_check check (status in ('draft', 'active', 'inactive'))
);

create table services (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  name text not null,
  category text,
  description text,
  duration_minutes integer not null default 30,
  price_amount numeric(10,2),
  price_currency text not null default 'UAH',
  is_price_from boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint services_status_check check (status in ('active', 'inactive'))
);

create table pets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  species text not null,
  breed text,
  sex text,
  birth_date date,
  approximate_age text,
  weight_kg numeric(6,2),
  photo_url text,
  allergies text,
  chronic_conditions text,
  health_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table pet_owners (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references pets(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  relationship text not null default 'primary_owner',
  created_at timestamptz not null default now(),
  unique (pet_id, user_id)
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id),
  doctor_id uuid references doctors(id),
  service_id uuid not null references services(id),
  pet_id uuid not null references pets(id),
  owner_id uuid not null references profiles(id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled',
  price_amount numeric(10,2),
  price_currency text not null default 'UAH',
  owner_comment text,
  clinic_comment text,
  cancelled_by uuid references profiles(id),
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointments_status_check check (status in ('scheduled', 'confirmed', 'cancelled', 'completed', 'no_show'))
);

create table visit_records (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid references appointments(id),
  clinic_id uuid not null references clinics(id),
  doctor_id uuid references doctors(id),
  pet_id uuid not null references pets(id),
  created_by uuid not null references profiles(id),
  visit_date timestamptz not null default now(),
  reason text,
  diagnosis text,
  treatment_notes text,
  recommendations text,
  internal_notes text,
  follow_up_at timestamptz,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint visit_records_status_check check (status in ('draft', 'completed'))
);

create table visit_documents (
  id uuid primary key default gen_random_uuid(),
  visit_record_id uuid not null references visit_records(id) on delete cascade,
  clinic_id uuid not null references clinics(id),
  pet_id uuid not null references pets(id),
  uploaded_by uuid not null references profiles(id),
  document_type text not null default 'other',
  title text,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text,
  file_size_bytes bigint,
  is_visible_to_owner boolean not null default true,
  created_at timestamptz not null default now(),
  constraint visit_documents_type_check check (
    document_type in ('diagnosis', 'recommendation', 'certificate', 'photo', 'lab_result', 'other')
  )
);

create table reviews (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id),
  doctor_id uuid references doctors(id),
  appointment_id uuid references appointments(id),
  owner_id uuid not null references profiles(id),
  rating integer not null check (rating between 1 and 5),
  comment text,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  unique (appointment_id, owner_id)
);

create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  plan text not null default 'free',
  status text not null default 'inactive',
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscriptions_plan_check check (plan in ('free', 'paid')),
  constraint subscriptions_status_check check (status in ('inactive', 'trialing', 'active', 'past_due', 'cancelled'))
);

create index profiles_role_idx on profiles(role);
create index clinics_status_idx on clinics(status);
create index clinic_members_user_idx on clinic_members(user_id);
create index clinic_members_clinic_idx on clinic_members(clinic_id);
create index doctors_clinic_idx on doctors(clinic_id);
create index doctors_profile_idx on doctors(profile_id);
create index services_clinic_idx on services(clinic_id);
create index pet_owners_user_idx on pet_owners(user_id);
create index appointments_owner_idx on appointments(owner_id);
create index appointments_clinic_idx on appointments(clinic_id);
create index appointments_doctor_idx on appointments(doctor_id);
create index visit_records_pet_idx on visit_records(pet_id);
create index visit_records_clinic_idx on visit_records(clinic_id);
create index visit_documents_visit_idx on visit_documents(visit_record_id);

alter table profiles enable row level security;
alter table clinics enable row level security;
alter table clinic_members enable row level security;
alter table doctors enable row level security;
alter table services enable row level security;
alter table pets enable row level security;
alter table pet_owners enable row level security;
alter table appointments enable row level security;
alter table visit_records enable row level security;
alter table visit_documents enable row level security;
alter table reviews enable row level security;
alter table subscriptions enable row level security;

