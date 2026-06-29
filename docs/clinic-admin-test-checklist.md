# Clinic Admin Test Checklist

Use this after applying migrations and creating a clinic owner account.

## Access

- Clinic owner can view `/dashboard`.
- Clinic manager can view `/dashboard`.
- Pet owner is blocked from clinic admin pages.
- Public logged-out user is redirected to `/login`.
- Clinic user cannot access another clinic's data.

## Clinic Profile

- Clinic owner can update clinic name.
- Clinic owner can update city, country, address, phone, email, website, logo URL, and cover URL.
- Publishing is blocked if name, city, address, and phone or email are missing.
- Success message appears after saving.

## Services

- Empty state appears when there are no services.
- Clinic owner can add a service.
- Service name is required.
- Duration must be positive when provided.
- Price must not be negative when provided.
- Clinic owner can edit service.
- Clinic owner can deactivate service.
- Delete archives instead of deleting when connected data exists.
- Veterinarian can view services but cannot manage them.

## Doctors

- Empty state appears when there are no doctors.
- Clinic owner can add a doctor.
- Full name is required.
- Specialization is required.
- Experience cannot be negative.
- Email must be valid when provided.
- Clinic owner can edit doctor profile.
- Clinic owner can deactivate doctor.
- Delete archives instead of deleting when connected data exists.

## Doctor Schedules

- Empty state appears when there are no schedules.
- Active doctor is required before adding schedule.
- Clinic owner can create weekly schedule row.
- Start time must be before end time.
- Break time must be inside working hours.
- Slot duration must be positive.
- Duplicate active schedule for the same doctor/day is blocked.
- Veterinarian can view own schedule.

