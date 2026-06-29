alter table clinics
  add column if not exists country text,
  add column if not exists published boolean not null default false;

alter table clinics
  drop constraint if exists clinics_status_check;

alter table clinics
  add constraint clinics_status_check check (status in ('draft', 'pending_verification', 'published', 'suspended'));

update clinics
set published = true
where status = 'published';

alter table services
  add column if not exists is_public boolean not null default true;

alter table services
  drop constraint if exists services_status_check;

alter table services
  add constraint services_status_check check (status in ('active', 'inactive', 'archived'));

alter table doctors
  add column if not exists phone text,
  add column if not exists email text,
  add column if not exists is_public boolean not null default true;

alter table doctors
  drop constraint if exists doctors_status_check;

alter table doctors
  add constraint doctors_status_check check (status in ('draft', 'active', 'inactive', 'archived'));

create table if not exists doctor_schedules (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references clinics(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  break_start_time time,
  break_end_time time,
  slot_duration_minutes integer not null default 30 check (slot_duration_minutes > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint doctor_schedules_time_check check (start_time < end_time),
  constraint doctor_schedules_break_check check (
    (break_start_time is null and break_end_time is null)
    or (
      break_start_time is not null
      and break_end_time is not null
      and start_time < break_start_time
      and break_start_time < break_end_time
      and break_end_time < end_time
    )
  )
);

create unique index if not exists doctor_schedules_unique_active_day_idx
  on doctor_schedules(doctor_id, day_of_week)
  where is_active = true;

create index if not exists clinics_published_idx on clinics(published);
create index if not exists services_status_idx on services(status);
create index if not exists doctors_status_idx on doctors(status);
create index if not exists doctor_schedules_clinic_idx on doctor_schedules(clinic_id);
create index if not exists doctor_schedules_doctor_idx on doctor_schedules(doctor_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_clinics_updated_at on clinics;
create trigger set_clinics_updated_at
before update on clinics
for each row execute function public.set_updated_at();

drop trigger if exists set_services_updated_at on services;
create trigger set_services_updated_at
before update on services
for each row execute function public.set_updated_at();

drop trigger if exists set_doctors_updated_at on doctors;
create trigger set_doctors_updated_at
before update on doctors
for each row execute function public.set_updated_at();

drop trigger if exists set_doctor_schedules_updated_at on doctor_schedules;
create trigger set_doctor_schedules_updated_at
before update on doctor_schedules
for each row execute function public.set_updated_at();

alter table doctor_schedules enable row level security;

drop policy if exists "public can read published clinics" on clinics;
drop policy if exists "clinics public published and members" on clinics;
create policy "clinics public published and members"
on clinics for select
using (
  (status = 'published' and published = true)
  or public.is_clinic_member(id)
  or public.is_platform_admin()
);

drop policy if exists "clinic owners update own clinic" on clinics;
create policy "clinic owners and managers update own clinic"
on clinics for update
using (
  public.has_clinic_role(id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

drop policy if exists "public reads active services from published clinics" on services;
create policy "public reads active public services from published clinics"
on services for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (
    status = 'active'
    and is_public = true
    and exists (
      select 1 from clinics
      where clinics.id = services.clinic_id
        and clinics.status = 'published'
        and clinics.published = true
    )
  )
);

drop policy if exists "clinic owners and managers manage services" on services;
drop policy if exists "clinic admins can manage services" on services;
create policy "clinic owners and managers manage services"
on services for all
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

drop policy if exists "public reads active doctors from published clinics" on doctors;
create policy "public reads active public doctors from published clinics"
on doctors for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or profile_id = auth.uid()
  or (
    status = 'active'
    and is_public = true
    and exists (
      select 1 from clinics
      where clinics.id = doctors.clinic_id
        and clinics.status = 'published'
        and clinics.published = true
    )
  )
);

drop policy if exists "clinic owners and managers manage doctors" on doctors;
drop policy if exists "clinic admins can manage doctors" on doctors;
create policy "clinic owners and managers manage doctors"
on doctors for all
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

create policy "clinic members read schedules"
on doctor_schedules for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or exists (
    select 1 from doctors
    where doctors.id = doctor_schedules.doctor_id
      and doctors.profile_id = auth.uid()
  )
);

create policy "clinic owners and managers manage schedules"
on doctor_schedules for all
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);

