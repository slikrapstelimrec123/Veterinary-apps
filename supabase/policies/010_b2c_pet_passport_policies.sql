-- B2C digital pet passport RLS policy reference.

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
