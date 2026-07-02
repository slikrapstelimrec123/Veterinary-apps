-- B2C-first digital pet passport module.
-- Keeps clinic marketplace features available for later pilot, but makes pet owner utility independent.

alter table pets add column if not exists sterilized boolean;
alter table pets add column if not exists allergies text;
alter table pets add column if not exists chronic_conditions text;
alter table pets add column if not exists owner_contact_name text;
alter table pets add column if not exists owner_contact_phone text;
alter table pets add column if not exists owner_contact_email text;
alter table pets add column if not exists emergency_contact text;

create table if not exists pet_health_events (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references pets(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  title text not null,
  date_done date not null,
  next_due_date date,
  clinic_name text,
  doctor_name text,
  notes text,
  document_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_health_events_type_check check (
    type in ('vaccination', 'tick_treatment', 'parasite_treatment', 'deworming', 'medication', 'grooming', 'nail_trim', 'food_reminder', 'vet_visit', 'other')
  )
);

create table if not exists pet_documents (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references pets(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  file_name text,
  file_type text,
  file_size integer,
  storage_path text,
  document_type text not null default 'other',
  title text not null,
  description text,
  document_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_documents_type_check check (
    document_type in ('vet_passport', 'lab_result', 'prescription', 'certificate', 'receipt', 'vaccination', 'photo', 'other')
  )
);

alter table pet_health_events
  drop constraint if exists pet_health_events_document_id_fkey;

alter table pet_health_events
  add constraint pet_health_events_document_id_fkey
  foreign key (document_id) references pet_documents(id) on delete set null;

create table if not exists pet_reminders (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references pets(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  title text not null,
  description text,
  due_date date not null,
  repeat_rule text,
  status text not null default 'upcoming',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pet_reminders_type_check check (
    type in ('vaccination', 'tick_treatment', 'parasite_treatment', 'deworming', 'medication', 'grooming', 'nails', 'food', 'vet_visit', 'custom')
  ),
  constraint pet_reminders_status_check check (status in ('upcoming', 'completed', 'overdue', 'skipped', 'cancelled'))
);

create table if not exists pet_public_profiles (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references pets(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  public_slug text not null unique,
  is_enabled boolean not null default false,
  show_owner_name boolean not null default false,
  show_phone boolean not null default false,
  show_email boolean not null default false,
  show_emergency_contact boolean not null default false,
  public_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists waitlist_leads (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text,
  phone text,
  pet_type text,
  source text,
  consent boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists pet_health_events_owner_pet_idx on pet_health_events(owner_id, pet_id, date_done desc);
create index if not exists pet_documents_owner_pet_idx on pet_documents(owner_id, pet_id, created_at desc);
create index if not exists pet_reminders_owner_status_idx on pet_reminders(owner_id, status, due_date);
create index if not exists pet_public_profiles_pet_idx on pet_public_profiles(pet_id);
create index if not exists pet_public_profiles_enabled_idx on pet_public_profiles(public_slug) where is_enabled = true;
create index if not exists waitlist_leads_email_idx on waitlist_leads(email);

alter table pet_health_events enable row level security;
alter table pet_documents enable row level security;
alter table pet_reminders enable row level security;
alter table pet_public_profiles enable row level security;
alter table waitlist_leads enable row level security;

drop policy if exists "owners manage own health events" on pet_health_events;
drop policy if exists "owners manage own pet documents" on pet_documents;
drop policy if exists "owners manage own reminders" on pet_reminders;
drop policy if exists "owners manage own public pet cards" on pet_public_profiles;
drop policy if exists "public reads enabled pet public cards" on pet_public_profiles;
drop policy if exists "anyone can join waitlist" on waitlist_leads;
drop policy if exists "platform admins manage waitlist" on waitlist_leads;

create policy "owners manage own health events"
on pet_health_events for all
using (owner_id = auth.uid() and public.owns_pet(pet_id))
with check (owner_id = auth.uid() and public.owns_pet(pet_id));

create policy "owners manage own pet documents"
on pet_documents for all
using (owner_id = auth.uid() and public.owns_pet(pet_id))
with check (owner_id = auth.uid() and public.owns_pet(pet_id));

create policy "owners manage own reminders"
on pet_reminders for all
using (owner_id = auth.uid() and public.owns_pet(pet_id))
with check (owner_id = auth.uid() and public.owns_pet(pet_id));

create policy "owners manage own public pet cards"
on pet_public_profiles for all
using (owner_id = auth.uid() and public.owns_pet(pet_id))
with check (owner_id = auth.uid() and public.owns_pet(pet_id));

create policy "public reads enabled pet public cards"
on pet_public_profiles for select
using (is_enabled = true);

create policy "anyone can join waitlist"
on waitlist_leads for insert
with check (consent = true);

create policy "platform admins manage waitlist"
on waitlist_leads for all
using (public.is_platform_admin())
with check (public.is_platform_admin());
