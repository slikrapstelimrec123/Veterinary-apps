-- Reviews and ratings RLS.
-- Clinics can read and report context, but cannot edit/delete pet owner review text.

drop policy if exists "public reads published reviews" on reviews;
drop policy if exists "owners create reviews for completed appointments" on reviews;
drop policy if exists "reviews public and connected read" on reviews;
drop policy if exists "pet owners create eligible reviews" on reviews;
drop policy if exists "pet owners update own editable reviews" on reviews;
drop policy if exists "platform admins moderate reviews" on reviews;

create policy "reviews public and connected read"
on reviews for select
using (
  status = 'published'
  or owner_id = auth.uid()
  or public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
);

create policy "pet owners create eligible reviews"
on reviews for insert
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from profiles
    where profiles.id = auth.uid()
      and profiles.role = 'pet_owner'
  )
  and public.can_user_review_appointment(auth.uid(), appointment_id)
);

create policy "pet owners update own editable reviews"
on reviews for update
using (
  owner_id = auth.uid()
  and status in ('pending_moderation', 'published')
)
with check (
  owner_id = auth.uid()
  and status in ('pending_moderation', 'published')
);

create policy "platform admins moderate reviews"
on reviews for update
using (public.is_platform_admin())
with check (public.is_platform_admin());
