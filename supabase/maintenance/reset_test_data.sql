-- Destructive reset for the pre-TestFlight Supabase project.
--
-- Run this manually in the Supabase SQL Editor only after confirming that the
-- project contains no real users or clinic data. Schema objects, RLS policies,
-- storage buckets, and subscription plan configuration are preserved.

begin;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'account_deletion_requests',
    'pet_transfers',
    'pet_achievements',
    'pet_feedings',
    'pet_medications',
    'beta_feedback',
    'notification_delivery_log',
    'scheduled_notifications',
    'notifications',
    'notification_preferences',
    'subscription_upgrade_requests',
    'subscription_usage',
    'clinic_subscriptions',
    'subscriptions',
    'reviews',
    'visit_documents',
    'visit_records',
    'appointments',
    'doctor_schedules',
    'services',
    'doctors',
    'clinic_members',
    'pet_owners',
    'pets',
    'clinics',
    'profiles'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format(
        'truncate table public.%I restart identity cascade',
        table_name
      );
    end if;
  end loop;
end
$$;

-- Removing Auth users also clears their sessions and identities through the
-- foreign keys managed by Supabase Auth.
delete from auth.users;

commit;

-- Uploaded objects must be removed through the Supabase Storage dashboard or
-- Storage API. Do not delete rows directly from storage.objects: that can leave
-- orphaned files in the underlying storage provider.
