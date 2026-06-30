# Veterinary Platform Architecture

## 1. Product Surfaces

### Mobile App For Pet Owners

Recommended stack:

- Flutter
- Dart
- Supabase client
- Riverpod or Bloc for state management
- GoRouter for navigation
- Cached network images for avatars/photos
- Secure storage for session tokens where appropriate

Primary responsibilities:

- Owner authentication.
- Pet profiles.
- Clinic and doctor browsing.
- Appointment booking.
- Appointment history.
- Pet medical card.
- Private document viewing through signed URLs.

Current pet owner module:

- `AuthGate` routes pet owners into the mobile app and blocks clinic/platform roles from the pet owner MVP surface.
- `HomeScreen` shows greeting, pet count, pet previews, add-pet CTA, and clinic-search placeholder.
- `PetListScreen` lists pets owned by the current user.
- `PetFormScreen` creates and edits pet profiles.
- `PetProfileScreen` shows pet medical card details and quick cards.
- `VisitHistoryScreen` reads completed visit records for a selected pet.
- `VisitRecordDetailsScreen` shows diagnosis, treatment notes, recommendations, follow-up, and document metadata.
- `DocumentsScreen` shows owner-visible private document metadata and requests signed URLs for allowed files.
- `ClinicListScreen` lists published clinics with simple name/city search.
- `ClinicProfileScreen` shows public clinic details, services, doctors, and a booking action.
- `DoctorProfileScreen` shows public doctor details and routes to booking.
- `AppointmentBookingScreen` lets an owner choose pet, clinic, service, doctor, date, and generated free slot. If a clinic cannot accept online booking because of internal clinic limits, the owner sees only a generic temporary-unavailable message.
- `MyAppointmentsScreen` and `AppointmentDetailsScreen` show owner appointments and allow owner cancellation while pending or confirmed.
- Mock mode is enabled with `MOCK_MODE=true` or missing Supabase env values.

Real document viewing/upload, chat, payments, and push notifications are intentionally not part of this stage. Reviews and ratings now exist as a focused MVP module after completed appointments.

## Reviews And Ratings Flow

- Reviews are tied to `clinic_id`, optional `doctor_id`, `appointment_id`, optional `visit_record_id`, `pet_id`, and `owner_id`.
- A pet owner can review only their own completed appointment or an appointment with a published visit record.
- One appointment can have only one review from the owner.
- The mobile app shows the review CTA from appointment details and published visit record details.
- Clinic and doctor profile screens load published reviews plus `clinic_rating_summary` / `doctor_rating_summary`.
- Clinic staff can view reviews in `/clinic/reviews` and open `/clinic/reviews/[id]`; they cannot edit or delete review text.
- Platform admins can change review status in `/platform/reviews`.
- MVP moderation publishes reviews immediately; `pending_moderation`, `hidden`, `reported`, and `removed` statuses are supported for future moderation workflows.

### Web Admin Panel For Clinics

Recommended stack:

- Next.js with App Router
- TypeScript
- Supabase JavaScript client
- TanStack Query for data fetching
- React Hook Form with Zod validation
- Tailwind CSS or a restrained component system
- shadcn/ui can be used carefully for admin UI foundations

Primary responsibilities:

- Clinic onboarding.
- Clinic profile management.
- Doctor management.
- Services and prices.
- Schedules.
- Appointments.
- Clients and pet cards.
- Visit records.
- Document uploads.

Current clinic admin module:

- `/dashboard` shows clinic status, active doctor count, active service count, and profile completion.
- `/clinic/profile` edits clinic profile and publication readiness.
- `/clinic/services` manages service catalog records.
- `/clinic/doctors` manages doctor profiles.
- `/clinic/doctors/[id]` shows and edits a doctor profile.
- `/clinic/schedule` manages weekly doctor availability.
- `/clinic/appointments` lists clinic appointments.
- `/clinic/appointments/[id]` shows appointment details, status controls for owner/manager roles, optional doctor assignment, and a visit-record action.
- `/clinic/appointments/[id]/visit-record/create` creates a medical visit record from an appointment.
- `/clinic/visit-records` lists clinic visit records.
- `/clinic/visit-records/[id]` shows diagnosis, treatment notes, recommendations, internal notes, and private document metadata.
- `/clinic/visit-records/[id]/edit` edits draft/published/archived records.
- `/clinic/subscription` shows current clinic plan, status, usage, and upgrade state.
- `/clinic/subscription/plans` shows Free, Basic, Pro, and Enterprise plans from the database.
- `/clinic/subscription/usage` shows calculated usage against plan limits.
- `/clinic/subscription/billing-placeholder` explains that real payment processing is not implemented.
- `/platform/subscription-requests` lets a platform admin manually approve or reject mock upgrade requests.

This module intentionally does not implement real payments, chat, push notifications, or AI features. Reviews are implemented only as post-appointment feedback, not as advanced marketplace ranking.

## Clinic Subscription Flow

- Plan definitions live in `subscription_plans` with configurable JSONB `limits` and `features`.
- Each clinic receives a current row in `clinic_subscriptions`; the Free plan is seeded for existing clinics.
- Usage is calculated dynamically with `get_clinic_usage(clinic_id)` from doctors, services, appointments, visit records, and visit documents.
- Database helpers expose plan checks such as `can_clinic_add_doctor`, `can_clinic_create_appointment`, and `can_clinic_upload_document`.
- Admin server actions call helper checks before high-impact mutations.
- Upgrade requests are stored in `subscription_upgrade_requests` and can be manually approved by a platform admin.
- Pet owners never see clinic billing, plan, or payment status.

### Backend And Database

Recommended stack:

- Supabase Auth
- Supabase PostgreSQL
- Supabase Row Level Security
- Supabase Storage
- Edge Functions only where direct client access is not enough

Primary responsibilities:

- Authentication.
- Role-based authorization.
- Data storage.
- Private file storage.
- Public published profiles.
- Appointment availability validation.

## 2. Project Structure

Suggested monorepo:

```text
apps/
  mobile/
    lib/
      app/
      features/
        auth/
        pets/
        clinics/
        booking/
        appointments/
        visit_history/
        documents/
      shared/
        ui/
        theme/
        services/
        models/
  clinic-admin/
    app/
    components/
    features/
      auth/
      onboarding/
      clinic-profile/
      doctors/
      services/
      schedules/
      appointments/
      clients/
      pets/
      visit-records/
      documents/
    lib/
      supabase/
      auth/
      validation/
      permissions/
packages/
  shared-types/
  database/
    migrations/
    seed/
docs/
  prd.md
  architecture.md
  database-schema.md
  user-flows.md
  roadmap.md
```

## 3. Navigation Structure

### Mobile App

Authentication:

- Welcome
- Sign in
- Sign up
- Forgot password

Main tabs:

- Pets
- Clinics
- Appointments
- Profile

Pets tab:

- Pet list
- Add/edit pet
- Pet card
- Treatment history
- Visit detail
- Documents

Clinics tab:

- Clinic search/list
- Clinic card
- Doctor list
- Doctor card
- Service list
- Booking flow

Appointments tab:

- Upcoming appointments
- Past appointments
- Appointment detail
- Cancel appointment confirmation

Profile tab:

- Owner profile
- Account settings
- Notification settings later
- Help/support later

### Clinic Web Admin

Main sections:

- Dashboard
- Appointments
- Clients
- Pets
- Visit Records
- Doctors
- Services
- Schedule
- Documents
- Clinic Profile
- Team
- Subscription
- Settings

### Optional Future Doctor Interface

Could be a limited responsive web workspace or mobile/tablet surface:

- Today
- Schedule
- Appointment detail
- Pet card
- Add visit record
- Documents
- Profile

## 4. MVP Screen List

### Mobile: Welcome

Purpose: introduce the product and route users into sign in/sign up.

Main elements:

- Product name.
- Short value statement.
- Sign in button.
- Create account button.

Primary actions:

- Sign in.
- Create account.

Empty states:

- Not applicable.

UX notes:

- Keep calm and direct. Do not make a marketing landing page inside the app.

### Mobile: Sign In / Sign Up

Purpose: authenticate pet owners.

Main elements:

- Email.
- Password.
- Full name and phone for sign up.
- Forgot password.

Primary actions:

- Continue.

Empty states:

- Not applicable.

UX notes:

- Keep errors plain and recoverable.

### Mobile: Pet List

Purpose: show owner's pets.

Main elements:

- Pet cards with photo, name, species, key note.
- Add pet action.

Primary actions:

- Open pet card.
- Add pet.

Empty states:

- No pets yet, with `Add pet` as the main action.

UX notes:

- This is the emotional home of the app.

### Mobile: Add/Edit Pet

Purpose: create or update pet profile.

Main elements:

- Photo.
- Name.
- Species.
- Breed.
- Sex.
- Birth date or approximate age.
- Weight.
- Allergies.
- Health notes.

Primary actions:

- Save pet.

Empty states:

- Optional fields can remain empty.

UX notes:

- Do not force owners to know every medical detail.

### Mobile: Pet Card

Purpose: central health profile for a pet.

Main elements:

- Pet header.
- Health summary.
- Upcoming appointment.
- Recent visits.
- Documents.
- Allergies and notes.

Primary actions:

- Book appointment.
- Open history.
- Open documents.
- Edit pet.

Empty states:

- No visits yet.
- No documents yet.

UX notes:

- Key health data should be reachable in 1-2 taps.

### Mobile: Clinic Search/List

Purpose: let owners find published clinics.

Main elements:

- Search.
- City/filter later.
- Clinic cards.
- Rating if available.
- Address and working hours.

Primary actions:

- Open clinic.

Empty states:

- No clinics found.

UX notes:

- MVP search can be simple by city/name.

### Mobile: Clinic Card

Purpose: show clinic details and lead to booking.

Main elements:

- Clinic photo/logo.
- Name.
- Address.
- Working hours.
- Contact info.
- Services.
- Doctors.
- Reviews later.

Primary actions:

- Book appointment.
- Open doctor.
- Select service.

Empty states:

- No doctors or services available.

UX notes:

- Clinic can be visible but not bookable if setup is incomplete.

### Mobile: Booking Flow

Purpose: create an appointment.

Main elements:

- Pet selector.
- Service selector.
- Doctor selector.
- Date selector.
- Time slots.
- Review screen.

Primary actions:

- Confirm appointment.

Empty states:

- No pets.
- No available slots.

UX notes:

- Re-check slot availability on confirmation.

### Mobile: My Appointments

Purpose: show upcoming and past appointments.

Main elements:

- Appointment cards.
- Status badge.
- Date/time.
- Pet, clinic, doctor, service.

Primary actions:

- Open appointment.
- Cancel appointment if allowed.

Empty states:

- No appointments, with booking action.

UX notes:

- Separate upcoming and past.

### Mobile: Visit Detail

Purpose: show completed visit information.

Main elements:

- Clinic and doctor.
- Diagnosis.
- Treatment notes.
- Recommendations.
- Documents/photos.

Primary actions:

- Open document.
- Book follow-up.

Empty states:

- No documents attached.

UX notes:

- Do not show clinic internal notes.

### Web: Clinic Onboarding

Purpose: guide clinic setup.

Main elements:

- Setup checklist.
- Profile completeness.
- Required actions.

Primary actions:

- Complete profile.
- Add service.
- Add doctor.
- Add schedule.
- Publish clinic.

Empty states:

- New clinic with incomplete setup.

UX notes:

- This page reduces support work.

### Web: Dashboard

Purpose: daily operational overview.

Main elements:

- Today appointments.
- New bookings.
- Pending visit records.
- Profile status.

Primary actions:

- Open appointment.
- Add appointment manually later.

Empty states:

- No appointments today.

UX notes:

- Keep it practical, not analytics-heavy in MVP.

### Web: Appointments

Purpose: manage clinic appointments.

Main elements:

- List/calendar.
- Filters by date, doctor, status.
- Appointment detail.

Primary actions:

- Change status.
- Open pet card.
- Create visit record.

Empty states:

- No appointments for selected date.

UX notes:

- Receptionists must scan quickly.

### Web: Doctors

Purpose: manage clinic doctors.

Main elements:

- Doctor list.
- Doctor form.
- Active/draft status.

Primary actions:

- Add doctor.
- Edit doctor.
- Deactivate doctor.

Empty states:

- No doctors yet.

UX notes:

- Warn when doctor has no schedule.

### Web: Services

Purpose: manage bookable services and prices.

Main elements:

- Service list.
- Price.
- Duration.
- Assigned doctors.

Primary actions:

- Add service.
- Edit service.
- Deactivate service.

Empty states:

- No services yet.

UX notes:

- Keep pricing clear, allow `from` price later.

### Web: Schedule

Purpose: configure doctor availability.

Main elements:

- Doctor selector.
- Weekly schedule.
- Breaks.
- Time slots preview.

Primary actions:

- Save schedule.

Empty states:

- No doctor selected.

UX notes:

- MVP can use weekly recurring availability.

### Web: Clients And Pets

Purpose: view clients and pet cards connected to the clinic.

Main elements:

- Client list.
- Pet list.
- Pet card.
- Visit history.

Primary actions:

- Open pet card.
- Open visit.

Empty states:

- No clients yet.

UX notes:

- Clinic should only see clients/pets that have clinic relationship.

### Web: Visit Record

Purpose: create medical record after an appointment.

Main elements:

- Appointment context.
- Pet summary.
- Diagnosis.
- Treatment notes.
- Recommendations.
- Internal notes.
- Attachments.

Primary actions:

- Save draft.
- Complete visit.
- Upload document.

Empty states:

- New blank record.

UX notes:

- Make draft/completed visibility obvious.

## 5. UI System Direction

### Visual Style

- Premium, calm, minimal, medical.
- Warm light background.
- Deep blue or graphite as primary.
- Soft green for successful medical-safe states.
- Sand/milk neutrals for surfaces.
- Avoid acidic colors and crowded layouts.

### Components

- Bottom navigation for mobile.
- Left sidebar for clinic web admin.
- Pet cards.
- Clinic cards.
- Doctor cards.
- Service rows.
- Status badges.
- Stepper for booking.
- Calendar/date selector.
- Time slot buttons.
- File upload dropzone.
- Confirmation modals for cancellation or destructive actions.
- Skeleton loading states.

### Accessibility And Usability

- Large tap targets on mobile.
- High contrast text.
- Plain error messages.
- No hidden critical actions.
- Clear status labels for appointment and visit record states.
- Forms split into small groups.

## 6. Authentication Approach

- Use Supabase Auth for email/password MVP.
- Store app role/profile data in `profiles`.
- Use `clinic_members` for clinic-specific roles.
- Use RLS for all sensitive data.
- Use app-level route guards for UX only; never rely on frontend checks alone.

## 7. File Storage Approach

- Use private Supabase Storage buckets.
- Store file metadata in `visit_documents`.
- Access files through signed URLs.
- Do not make medical files public.
- Separate public clinic media from private medical documents.

Suggested buckets:

- `public-clinic-media`
- `public-doctor-media`
- `visit-documents` for the implemented private visit-document bucket
- `private-pet-media` if owner uploads are enabled later

## 8. Deployment Approach

MVP deployment:

- Clinic web admin: Vercel.
- Supabase: managed Supabase project.
- Mobile app: internal TestFlight and Google Play internal testing.

Later:

- Production mobile release.
- Separate staging and production Supabase projects.
- Error monitoring with Sentry.
- Product analytics with privacy-safe events.

## 9. Testing Approach

Core tests:

- Database RLS tests for owner access, clinic access, doctor access, and public profile access.
- Booking conflict tests.
- Appointment status transition tests.
- File upload and signed URL access tests.
- Form validation tests.
- Manual QA for clinic onboarding and mobile booking.

Acceptance testing should focus on:

- Can a clinic set up profile, doctor, service, schedule?
- Can a pet owner create pet and book?
- Can clinic create a completed visit record?
- Can pet owner view that record?
- Can unauthorized users fail to access it?
