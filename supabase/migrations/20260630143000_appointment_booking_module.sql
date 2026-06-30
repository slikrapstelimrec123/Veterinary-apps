-- Appointment booking module for pet owners and clinic staff.
-- Keeps visit records, payments, chat, reviews, and reminders out of this MVP stage.

alter table appointments
  add column if not exists appointment_date date,
  add column if not exists start_time time,
  add column if not exists end_time time,
  add column if not exists owner_note text,
  add column if not exists clinic_note text,
  add column if not exists cancellation_reason text;

update appointments
set
  appointment_date = coalesce(appointment_date, starts_at::date),
  start_time = coalesce(start_time, starts_at::time),
  end_time = coalesce(end_time, ends_at::time),
  owner_note = coalesce(owner_note, owner_comment),
  clinic_note = coalesce(clinic_note, clinic_comment),
  status = case
    when status = 'scheduled' then 'pending'
    when status = 'cancelled' then 'cancelled_by_clinic'
    else status
  end
where appointment_date is null
   or start_time is null
   or end_time is null
   or owner_note is null
   or clinic_note is null
   or status in ('scheduled', 'cancelled');

alter table appointments
  alter column appointment_date set not null,
  alter column start_time set not null,
  alter column end_time set not null,
  alter column status set default 'pending',
  drop constraint if exists appointments_status_check,
  add constraint appointments_status_check check (
    status in (
      'pending',
      'confirmed',
      'completed',
      'cancelled_by_owner',
      'cancelled_by_clinic',
      'no_show'
    )
  ),
  drop constraint if exists appointments_time_check,
  add constraint appointments_time_check check (start_time < end_time);

create index if not exists appointments_date_idx on appointments(appointment_date);
create index if not exists appointments_status_idx on appointments(status);
create index if not exists appointments_pet_idx on appointments(pet_id);
create index if not exists appointments_doctor_date_idx on appointments(doctor_id, appointment_date);
create index if not exists appointments_owner_note_idx on appointments(owner_note) where owner_note is not null;
create index if not exists appointments_clinic_note_idx on appointments(clinic_note) where clinic_note is not null;
create index if not exists appointments_cancellation_reason_idx on appointments(cancellation_reason) where cancellation_reason is not null;

drop policy if exists "clinic members read schedules" on doctor_schedules;
create policy "clinic members and public read active schedules"
on doctor_schedules for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or exists (
    select 1 from doctors
    where doctors.id = doctor_schedules.doctor_id
      and doctors.profile_id = auth.uid()
  )
  or (
    is_active = true
    and exists (
      select 1
      from doctors
      join clinics on clinics.id = doctors.clinic_id
      where doctors.id = doctor_schedules.doctor_id
        and doctors.status = 'active'
        and doctors.is_public = true
        and clinics.status = 'published'
        and clinics.published = true
    )
  )
);

drop policy if exists "owners clinics doctors read appointments" on appointments;
drop policy if exists "owners create own pet appointments" on appointments;
drop policy if exists "clinic members manage clinic appointments" on appointments;
drop policy if exists "pet owners cancel own appointments" on appointments;
drop policy if exists "clinic owners managers update appointments" on appointments;

create policy "owners clinics doctors read appointments"
on appointments for select
using (
  owner_id = auth.uid()
  or public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
  or exists (
    select 1 from doctors
    where doctors.id = appointments.doctor_id
      and doctors.profile_id = auth.uid()
  )
);

create policy "owners create pending own pet appointments"
on appointments for insert
with check (
  owner_id = auth.uid()
  and status = 'pending'
  and public.owns_pet(pet_id)
  and exists (
    select 1
    from clinics
    where clinics.id = appointments.clinic_id
      and clinics.status = 'published'
      and clinics.published = true
  )
  and exists (
    select 1
    from services
    where services.id = appointments.service_id
      and services.clinic_id = appointments.clinic_id
      and services.status = 'active'
      and services.is_public = true
  )
  and (
    doctor_id is null
    or exists (
      select 1
      from doctors
      where doctors.id = appointments.doctor_id
        and doctors.clinic_id = appointments.clinic_id
        and doctors.status = 'active'
        and doctors.is_public = true
    )
  )
);

create policy "pet owners cancel own appointments"
on appointments for update
using (
  owner_id = auth.uid()
  and status in ('pending', 'confirmed')
)
with check (
  owner_id = auth.uid()
  and status = 'cancelled_by_owner'
);

create policy "clinic owners managers update appointments"
on appointments for update
using (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner', 'clinic_manager'])
  or public.is_platform_admin()
);
