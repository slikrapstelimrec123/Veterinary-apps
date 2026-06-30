-- Clinic management module RLS reference.
-- Applied migration: supabase/migrations/20260629153000_clinic_management_module.sql

-- clinics:
-- - public reads only status='published' and published=true
-- - clinic members read their clinic
-- - clinic_owner and clinic_manager update clinic profile
-- - platform_admin reads/updates all

-- services:
-- - clinic members read clinic services
-- - clinic_owner and clinic_manager create/update/delete services
-- - veterinarian reads clinic services
-- - public reads only active, public services from published clinics

-- doctors:
-- - clinic members read clinic doctors
-- - clinic_owner and clinic_manager create/update/delete doctors
-- - veterinarian can read their own linked doctor profile
-- - public reads only active, public doctors from published clinics

-- doctor_schedules:
-- - clinic members read schedules for their clinic
-- - clinic_owner and clinic_manager create/update/delete schedules
-- - veterinarian reads their own linked schedule
-- - public booking schedule access is extended in 004_appointment_booking_policies.sql
