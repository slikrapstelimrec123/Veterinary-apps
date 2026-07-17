-- Retire the discontinued clinic administration, booking, review, and clinic
-- subscription surfaces without deleting historical rows. Existing data stays
-- available to service-role maintenance only.

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'clinics',
    'clinic_members',
    'doctors',
    'services',
    'doctor_schedules',
    'appointments',
    'reviews',
    'subscriptions',
    'subscription_plans',
    'clinic_subscriptions',
    'subscription_usage',
    'subscription_upgrade_requests'
  ]
  loop
    if to_regclass(format('public.%I', target_table)) is not null then
      execute format(
        'revoke all privileges on table public.%I from anon, authenticated',
        target_table
      );
    end if;
  end loop;
end
$$;

do $$
declare
  target_function regprocedure;
begin
  for target_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'get_clinic_active_subscription',
        'get_clinic_plan_limits',
        'get_clinic_usage',
        'can_clinic_add_doctor',
        'can_clinic_add_service',
        'can_clinic_create_appointment',
        'can_clinic_create_visit_record',
        'can_clinic_upload_document',
        'can_clinic_publish_profile',
        'can_clinic_use_reviews',
        'has_user_reviewed_appointment',
        'can_user_review_appointment',
        'notify_subscription_limit_warning',
        'create_appointment_reminders',
        'cancel_appointment_reminders'
      )
  loop
    execute format(
      'revoke all privileges on function %s from public, anon, authenticated',
      target_function
    );
  end loop;
end
$$;

comment on schema public is
  'Lappo owner-only application schema. Legacy clinic and booking tables are retained for migration history but are not exposed to app roles.';
