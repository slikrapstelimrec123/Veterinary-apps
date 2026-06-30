-- Reference policy intent for appointment booking.
-- The executable version lives in supabase/migrations/20260630143000_appointment_booking_module.sql.

-- doctor_schedules:
-- Public users may read only active schedules for active public doctors in published clinics.
-- Clinic owners/managers may manage schedules through existing clinic catalog policies.
-- Veterinarians may read schedules linked to their doctor profile.

-- appointments:
-- Pet owners may read their own appointments.
-- Pet owners may create only pending appointments for pets they own in published clinics.
-- Pet owners may cancel only their own pending or confirmed appointments.
-- Clinic owners and clinic managers may read and update appointments in their clinic.
-- Veterinarians may read appointments assigned to their linked doctor profile.
-- Platform admins may read and update appointments for support and moderation.
