-- MVP Row Level Security helpers and policies.
-- Review with Supabase policy tests before beta launch.

create or replace function public.is_platform_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'platform_admin'
  );
$$;

create or replace function public.is_clinic_member(target_clinic_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from clinic_members
    where clinic_id = target_clinic_id
      and user_id = auth.uid()
      and status = 'active'
  );
$$;

create or replace function public.has_clinic_role(target_clinic_id uuid, allowed_roles text[])
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from clinic_members
    where clinic_id = target_clinic_id
      and user_id = auth.uid()
      and role = any(allowed_roles)
      and status = 'active'
  );
$$;

create or replace function public.owns_pet(target_pet_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from pet_owners
    where pet_id = target_pet_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.can_access_visit_record(target_visit_record_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from visit_records
    where id = target_visit_record_id
      and (
        public.is_platform_admin()
        or public.is_clinic_member(clinic_id)
        or (status = 'completed' and public.owns_pet(pet_id))
      )
  );
$$;

create policy "profiles read own or admin"
on profiles for select
using (
  id = auth.uid()
  or public.is_platform_admin()
  or exists (
    select 1
    from clinic_members member_self
    join clinic_members member_other on member_other.clinic_id = member_self.clinic_id
    where member_self.user_id = auth.uid()
      and member_self.status = 'active'
      and member_other.user_id = profiles.id
      and member_other.status = 'active'
  )
);

create policy "profiles update own"
on profiles for update
using (id = auth.uid())
with check (
  id = auth.uid()
  and role <> 'platform_admin'
);

create policy "profiles insert own"
on profiles for insert
with check (
  id = auth.uid()
  and role in ('pet_owner', 'clinic_owner')
);

create policy "clinics public published and members"
on clinics for select
using (
  status = 'published'
  or public.is_clinic_member(id)
  or public.is_platform_admin()
);

create policy "clinic owners create clinics"
on clinics for insert
with check (
  created_by = auth.uid()
  and exists (
    select 1 from profiles
    where id = auth.uid()
      and role in ('clinic_owner', 'platform_admin')
  )
);

create policy "clinic owners update own clinic"
on clinics for update
using (
  public.has_clinic_role(id, array['clinic_owner'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(id, array['clinic_owner'])
  or public.is_platform_admin()
);

create policy "clinic members read own clinic members"
on clinic_members for select
using (
  user_id = auth.uid()
  or public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
);

create policy "clinic owners manage members"
on clinic_members for all
using (
  public.has_clinic_role(clinic_id, array['clinic_owner'])
  or public.is_platform_admin()
)
with check (
  public.has_clinic_role(clinic_id, array['clinic_owner'])
  or (
    user_id = auth.uid()
    and role = 'clinic_owner'
    and status = 'active'
    and exists (
      select 1 from clinics
      where clinics.id = clinic_members.clinic_id
        and clinics.created_by = auth.uid()
        and clinics.status in ('draft', 'pending_verification')
    )
  )
  or public.is_platform_admin()
);

create policy "public reads active doctors from published clinics"
on doctors for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (
    status = 'active'
    and exists (
      select 1 from clinics
      where clinics.id = doctors.clinic_id
        and clinics.status = 'published'
    )
  )
);

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

create policy "public reads active services from published clinics"
on services for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (
    status = 'active'
    and exists (
      select 1 from clinics
      where clinics.id = services.clinic_id
        and clinics.status = 'published'
    )
  )
);

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

create policy "pet owners and connected clinics read pets"
on pets for select
using (
  public.owns_pet(id)
  or public.is_platform_admin()
  or exists (
    select 1 from appointments
    where appointments.pet_id = pets.id
      and public.is_clinic_member(appointments.clinic_id)
  )
  or exists (
    select 1 from visit_records
    where visit_records.pet_id = pets.id
      and public.is_clinic_member(visit_records.clinic_id)
  )
);

create policy "pet owners create pets"
on pets for insert
with check (
  exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'pet_owner'
  )
);

create policy "pet owners update own pets"
on pets for update
using (public.owns_pet(id))
with check (public.owns_pet(id));

create policy "pet owners read own ownership"
on pet_owners for select
using (
  user_id = auth.uid()
  or public.owns_pet(pet_id)
  or public.is_platform_admin()
);

create policy "pet owners create own ownership"
on pet_owners for insert
with check (user_id = auth.uid());

create policy "owners clinics doctors read appointments"
on appointments for select
using (
  owner_id = auth.uid()
  or public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
  or exists (
    select 1 from doctors
    where doctors.id = appointments.doctor_id
      and doctors.profile_id = auth.uid()
  )
);

create policy "owners create own pet appointments"
on appointments for insert
with check (
  owner_id = auth.uid()
  and public.owns_pet(pet_id)
);

create policy "clinic members manage clinic appointments"
on appointments for update
using (
  public.is_clinic_member(clinic_id)
  or owner_id = auth.uid()
  or public.is_platform_admin()
)
with check (
  public.is_clinic_member(clinic_id)
  or owner_id = auth.uid()
  or public.is_platform_admin()
);

create policy "owners and clinic members read visit records"
on visit_records for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (status = 'completed' and public.owns_pet(pet_id))
);

create policy "clinic medical staff create visit records"
on visit_records for insert
with check (
  (
    public.has_clinic_role(clinic_id, array['clinic_owner', 'veterinarian', 'clinic_manager'])
    or public.is_platform_admin()
  )
  and (
    appointment_id is null
    or exists (
      select 1 from appointments
      where appointments.id = visit_records.appointment_id
        and appointments.clinic_id = visit_records.clinic_id
        and appointments.pet_id = visit_records.pet_id
        and (
          public.has_clinic_role(visit_records.clinic_id, array['clinic_owner', 'clinic_manager'])
          or appointments.doctor_id = visit_records.doctor_id
          or public.is_platform_admin()
        )
    )
  )
);

create policy "clinic members update clinic visit records"
on visit_records for update
using (
  public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
)
with check (
  public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
);

create policy "owners and clinic members read visit documents"
on visit_documents for select
using (
  public.is_platform_admin()
  or public.is_clinic_member(clinic_id)
  or (
    is_visible_to_owner = true
    and public.owns_pet(pet_id)
    and public.can_access_visit_record(visit_record_id)
  )
);

create policy "clinic members create visit documents"
on visit_documents for insert
with check (
  public.is_clinic_member(clinic_id)
  and public.can_access_visit_record(visit_record_id)
);

create policy "public reads published reviews"
on reviews for select
using (
  is_published = true
  or owner_id = auth.uid()
  or public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
);

create policy "owners create reviews for completed appointments"
on reviews for insert
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from appointments
    where appointments.id = reviews.appointment_id
      and appointments.owner_id = auth.uid()
      and appointments.status = 'completed'
  )
);

create policy "clinic owners read subscriptions"
on subscriptions for select
using (
  public.has_clinic_role(clinic_id, array['clinic_owner'])
  or public.is_platform_admin()
);

-- Storage policy intent:
-- public-clinic-media: public read for published clinic/doctor media.
-- visit-documents: private only; create signed URLs after checking visit_documents RLS.
-- Do not expose SUPABASE_SERVICE_ROLE_KEY to admin or mobile clients.
