# Veterinary Platform User Flows

## 1. Clinic Registration

Goal: create a clinic workspace that can later be published to pet owners.

Steps:

1. Clinic owner opens web admin panel.
2. Enters email and password or uses approved OAuth provider.
3. Confirms email.
4. Creates clinic profile:
   - clinic name
   - legal or public name
   - phone
   - address
   - city
   - working hours
   - short description
   - main photo/logo
5. System creates:
   - `profiles` row
   - `clinics` record
   - `clinic_members` record with role `owner`
6. Clinic profile starts as `draft`.
7. Owner completes required setup checklist:
   - add at least one service
   - add at least one doctor
   - add schedule
8. Owner publishes clinic.

Key states:

- Empty profile: show setup checklist.
- Missing required fields: keep clinic in draft.
- Pending moderation later: show `pending_review`, outside MVP unless needed.

## 2. Adding A Doctor

Goal: add a veterinarian to a clinic profile and enable appointment booking.

Steps:

1. Clinic admin opens `Doctors`.
2. Taps `Add doctor`.
3. Enters:
   - full name
   - specialty
   - experience years
   - education
   - short bio
   - photo
   - services provided
   - appointment duration default
4. Optionally links doctor to an invited user account.
5. Saves doctor as `active` or `draft`.
6. Doctor appears in clinic admin.
7. Doctor appears publicly only if:
   - clinic is published
   - doctor is active
   - at least one service and available schedule exist

Key states:

- No doctors: show direct `Add doctor` action.
- Doctor draft: visible only to clinic team.
- Missing schedule: show warning, doctor cannot be booked.

## 3. Adding Services

Goal: define services that pet owners can book.

Steps:

1. Clinic admin opens `Services`.
2. Taps `Add service`.
3. Enters:
   - service name
   - category
   - description
   - duration
   - price
   - whether price is fixed or starts from
   - active status
4. Selects which doctors provide the service.
5. Saves service.
6. Service becomes visible on public clinic profile if active.

Key states:

- No services: show setup checklist item.
- Inactive service: hidden from pet owners.
- Service without doctor: visible only as information, not bookable.

## 4. Setting Doctor Schedule

Goal: make doctor availability bookable.

Steps:

1. Clinic admin opens `Schedule`.
2. Selects doctor.
3. Chooses weekly working days and hours.
4. Sets break times if needed.
5. Sets appointment duration or uses service duration.
6. Saves schedule.
7. Backend generates available slots dynamically from:
   - doctor schedule
   - service duration
   - existing appointments
   - blocked time
8. Pet owners can select available slots during booking.

Key states:

- No schedule: doctor cannot be booked.
- Fully booked day: show no available times.
- Clinic closed: hide date or mark unavailable.

## 5. Pet Owner Registration

Goal: create an account for a pet owner in the mobile app.

Steps:

1. Owner opens mobile app.
2. Chooses sign up.
3. Enters email, password, full name, phone.
4. Confirms email or phone if enabled.
5. Lands on empty pet list.
6. App prompts to add first pet.

Key states:

- No pets: primary action `Add pet`.
- Login error: show clear recoverable message.
- Unconfirmed email: show resend confirmation.

## 6. Creating A Pet Profile

Goal: create the pet medical card foundation.

Steps:

1. Owner taps `Add pet`.
2. Adds:
   - pet photo
   - name
   - species
   - breed
   - sex
   - birth date or approximate age
   - weight
   - allergies
   - chronic conditions or health notes
3. Saves pet.
4. System creates:
   - `pets` record
   - `pet_owners` relationship with role `primary_owner`
5. App opens pet card.

Key states:

- Missing pet name/species: block save.
- Unknown birthday: allow approximate age.
- No history yet: show calm empty treatment history.

## 7. Booking An Appointment

Goal: let a pet owner book a clinic visit in the fewest practical steps.

Steps:

1. Owner opens clinic profile or starts from `Book appointment`.
2. Selects pet.
3. Selects clinic.
4. Selects service.
5. Selects doctor if the service has multiple doctors.
6. Selects date and available time slot.
7. Reviews:
   - pet
   - clinic
   - doctor
   - service
   - date/time
   - price
   - cancellation note
8. Confirms appointment.
9. System creates appointment with status `scheduled`.
10. Appointment appears in:
   - owner's mobile app
   - clinic admin panel
   - doctor's schedule if linked

Key states:

- No pets: prompt to create pet first.
- No available slots: offer another date or doctor.
- Booking conflict: re-check availability before confirming.
- Success: show appointment detail and add-to-calendar option later.

## 8. Creating A Visit Record

Goal: clinic or doctor adds medical information after an appointment.

Steps:

1. Doctor or clinic staff opens appointment.
2. Opens pet card from appointment.
3. Taps `Create visit record`.
4. Enters:
   - visit date
   - reason for visit
   - diagnosis
   - treatment notes
   - recommendations
   - prescribed medication text, if needed
   - follow-up date, if needed
   - internal notes, clinic-only
5. Saves record as draft or completed.
6. If completed, record becomes visible to pet owner except internal notes.
7. Appointment status changes to `completed`.

Key states:

- Draft record: clinic-only.
- Completed record: visible to owner.
- Missing required fields: keep as draft.

## 9. Uploading Documents And Photos

Goal: attach medical files to a pet visit.

Steps:

1. Doctor or clinic staff opens visit record.
2. Taps `Upload document/photo`.
3. Selects file.
4. Adds file type:
   - diagnosis
   - lab result
   - certificate
   - image
   - prescription
   - other
5. File uploads to private Supabase Storage bucket.
6. Metadata is saved in `visit_documents`.
7. Owner can view file through authorized signed URL.

Key states:

- Upload progress.
- Upload error with retry.
- Unsupported file type.
- File visible to owner only when visit record is visible.

## 10. Pet Owner Viewing Treatment History

Goal: owner can understand pet history without calling the clinic.

Steps:

1. Owner opens pet card.
2. Opens `History`.
3. Sees visits sorted newest first.
4. Selects a visit.
5. Views:
   - clinic
   - doctor
   - visit date
   - diagnosis
   - treatment notes
   - recommendations
   - attached documents/photos
6. Opens files through secure signed links.

Key states:

- No visits: show empty history and booking action.
- Loading documents: show skeleton rows.
- Access denied: show support-safe message without leaking data.
