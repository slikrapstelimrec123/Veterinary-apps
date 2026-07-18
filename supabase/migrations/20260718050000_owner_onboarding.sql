-- One-time owner onboarding state.
--
-- Existing users are backfilled as complete so a release update never forces
-- beta users through a first-registration flow. Profiles created after this
-- migration keep the value null until the owner finishes or skips onboarding.

alter table public.profiles
  add column if not exists onboarding_completed_at timestamptz;

update public.profiles
set onboarding_completed_at = coalesce(onboarding_completed_at, now())
where onboarding_completed_at is null;

revoke update (onboarding_completed_at) on table public.profiles
  from anon, authenticated;
grant update (onboarding_completed_at)
  on table public.profiles to authenticated;
