# Veterinary Platform Roadmap

## Stage 1: Documentation And Project Setup

Goal: align product, architecture, and scope before code.

Deliverables:

- PRD.
- Architecture document.
- Database schema.
- User flows.
- Roadmap.
- Design direction.
- Monorepo setup.
- Environment strategy: local, staging, production later.

Acceptance criteria:

- MVP scope is clear.
- Non-MVP features are explicitly parked.
- Technical stack is agreed:
  - Flutter mobile app.
  - Next.js clinic admin.
  - Supabase backend.
- Repository structure is ready.

## Stage 2: Database And Authentication

Status: in progress. Initial Supabase Auth, profiles, roles, clinic membership, RLS helpers, admin guards, and mobile auth state are scaffolded.

Goal: create a secure foundation.

Deliverables:

- Supabase project.
- Database migrations.
- Auth setup.
- Core RLS policies.
- Storage buckets.
- Seed data for testing.
- Basic typed database client setup.

Core tables:

- profiles
- clinics
- clinic_members
- doctors
- services
- doctor_services
- doctor_schedules
- pets
- pet_owners
- appointments
- visit_records
- visit_documents
- subscriptions

Acceptance criteria:

- Pet owner can access only own pets.
- Clinic can access only own clinic workspace.
- Public users can access only published profiles.
- Private file access requires authorization.

## Stage 3: Clinic Admin Panel

Status: in progress. Clinic dashboard, clinic profile editing, services, doctors, and doctor schedules are scaffolded with Supabase data, server actions, validation, and RLS updates.

Goal: let clinics configure their workspace.

Deliverables:

- Web admin authentication.
- Clinic onboarding.
- Clinic profile editor.
- Doctor management.
- Service management.
- Schedule management.
- Simple dashboard.

Acceptance criteria:

- Clinic owner can register and create clinic.
- Clinic owner can add doctor, services, and schedule.
- Clinic can publish profile only after required setup.
- Staff can understand setup status without support.

## Stage 4: Mobile Pet Owner App

Status: in progress. Pet owner home, pet list, pet creation/editing, pet details, treatment history, visit details, private document metadata, reviews after completed appointments, clinic/doctor rating display, settings, logout, and mock preview mode are implemented.

Goal: let pet owners create account, pets, and browse clinics.

Deliverables:

- Mobile authentication.
- Owner profile.
- Pet list.
- Add/edit pet.
- Pet card.
- Clinic list/search.
- Clinic card.
- Doctor and service views.

Acceptance criteria:

- Owner can create account.
- Owner can add at least one pet.
- Owner can view published clinics.
- Owner can view clinic services and doctors.
- Owner cannot see private clinic data.

## Stage 5: Appointment Booking

Status: in progress. Mobile clinic discovery, clinic/doctor profiles, booking flow, owner appointment list/details/cancel, clinic appointment list/details, and basic clinic status management are scaffolded.

Goal: close the core booking loop between owner and clinic.

Deliverables:

- Booking flow in mobile app.
- Available slot calculation.
- Appointment creation.
- Appointment list for owner.
- Appointment list/calendar for clinic.
- Appointment status updates.

Acceptance criteria:

- Owner can book a valid available slot.
- Booking prevents double-booking.
- Clinic sees new appointment.
- Owner sees appointment.
- Clinic can confirm, cancel, complete, or mark no-show.
- Visit record creation is handled in Stage 6.

## Stage 6: Visit History And Document Uploads

Status: in progress. Clinic visit record creation/editing, draft/published/archive statuses, private document metadata/upload flow, and owner treatment-history viewing are scaffolded.

Goal: prove the main long-term value: pet medical history.

Deliverables:

- Visit record creation in clinic admin.
- Draft/completed visit record states.
- Private document upload.
- Visit history in pet owner mobile app.
- Secure document viewing.

Acceptance criteria:

- Clinic can create completed visit record.
- Owner can view completed record for own pet.
- Owner cannot view draft record.
- Owner cannot view internal clinic notes.
- Files are stored privately and accessed through authorized signed URLs.

## Stage 7: Testing And Beta Launch

Goal: validate with 5-10 real clinics.

Deliverables:

- Manual QA checklist.
- RLS/security test suite.
- Booking conflict tests.
- Mobile internal testing builds.
- Admin panel staging deployment.
- Beta onboarding guide for clinics.
- Feedback collection process.

Acceptance criteria:

- 5-10 clinics can onboard.
- At least one real appointment can be booked and completed per clinic.
- Pet owners can see visit history after clinic creates records.
- No known critical authorization gaps.
- Support issues are tracked and prioritized.

## Post-MVP Expansion

Build only after MVP learning:

- Paid clinic plans.
- Payment provider integration.
- Push notifications and reminders.
- Reviews UI, clinic rating, and doctor rating MVP are implemented.
- Clinic analytics.
- Chat.
- Multi-branch clinics.
- Advanced search and filters.
- Doctor-facing mobile/tablet workspace.
- Owner premium plan.
- Clinic CRM campaigns.
- Lab integrations.

## Subscription Logic

### MVP

Do not implement real payments.

Implemented architecture:

- Create `subscription_plans`, `clinic_subscriptions`, `subscription_usage`, and `subscription_upgrade_requests`.
- Create `free` plan by default for every clinic.
- Keep plan limits in database JSONB configuration, not scattered through UI logic.
- Show clinic subscription section with usage, limits, plans, and manual upgrade request flow.

### Future Free Clinic Plan

Possible limits:

- 1 clinic profile.
- Limited number of doctors.
- Limited number of monthly appointments.
- Basic pet records.
- Basic document uploads.

Purpose:

- Let clinics test the platform before paying.

### Future Paid Clinic Plan

Possible benefits:

- More doctors.
- More appointments.
- More storage.
- Advanced schedule management.
- CRM and reminders.
- Analytics.
- Priority support.
- Branding options.

Payment providers:

- Stripe where supported.
- Local provider if needed for target market.

### Optional Future Pet Owner Premium

Do not build in early stages.

Possible benefits later:

- Extra pet profiles.
- Advanced reminders.
- Family sharing.
- Exportable medical history.
- Cloud backup for owner-uploaded files.

Use Apple/Google subscriptions only when there is a clear consumer premium value.

## Technical Decisions

### Main Packages

Flutter mobile:

- `supabase_flutter`
- `go_router`
- `flutter_riverpod` or `bloc`
- `freezed`
- `json_serializable`
- `cached_network_image`
- `file_picker`
- `intl`

Next.js admin:

- `@supabase/supabase-js`
- `@supabase/ssr`
- `@tanstack/react-query`
- `react-hook-form`
- `zod`
- `date-fns`
- `tailwindcss`
- `lucide-react`

Backend:

- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Supabase Edge Functions for signed document access and webhooks later

### Authentication

- Email/password in MVP.
- Supabase Auth user ID is the primary identity.
- User profile data lives in `profiles`.
- Clinic roles live in `clinic_members`.
- Route guards improve UX, RLS provides real protection.

### File Storage

- Public bucket for clinic/doctor media.
- Private bucket for visit documents.
- Store file metadata in database.
- Generate signed URLs only after access check.

### Testing

- RLS policy tests are mandatory.
- Add booking conflict tests before beta.
- Test clinic setup manually with non-technical users.
- Test mobile booking on both iOS and Android.

### Deployment

- Vercel for clinic admin.
- Supabase managed backend.
- TestFlight and Google Play internal testing for beta.
- Separate staging and production before public release.

## MVP Build Order

Recommended order:

1. Database, auth, and RLS.
2. Clinic onboarding.
3. Doctors, services, schedules.
4. Mobile pet profiles.
5. Public clinic browsing.
6. Booking.
7. Clinic appointment management.
8. Visit records.
9. Documents.
10. Security testing.
11. Beta launch.
## Stage 7: Reviews And Ratings

Status: implemented for MVP.

Goal: allow trustworthy post-appointment feedback without fake or duplicate reviews.

Scope:

- One owner review per completed appointment.
- Review CTA from completed appointment details and published visit record details.
- Clinic and doctor rating summaries from published reviews only.
- Clinic review list/detail pages.
- Basic platform moderation placeholder.

Out of scope:

- Payments.
- Subscriptions.
- Chat.
- Push notifications.
- AI review analysis.
- Advanced marketplace ranking.
- Clinic replies.

## Stage 8: Clinic Subscriptions And Plan Limits

Status: implemented for MVP without real payments.

Goal: prepare SaaS monetization for clinics with configurable limits and safe manual upgrade flow.

Scope:

- `Free`, `Basic`, `Pro`, and `Enterprise` plans in the database.
- Configurable JSONB limits for doctors, services, appointments, visit records, documents, storage, profile publishing, reviews, analytics, export, multi-location, and priority support.
- Clinic subscription overview, plans, usage, and billing placeholder pages.
- Mock upgrade request flow with platform admin approval.
- Server-side limit checks before adding doctors/services, confirming appointments, creating visit records, uploading documents, and publishing clinic profile.
- Mobile pet owner booking shows only a generic unavailable message when a clinic cannot accept online booking.

Out of scope:

- Stripe, LiqPay, WayForPay, Fondy, Apple Billing, Google Billing.
- Card collection.
- Downgrade data deletion.
- Aggressive paywalls.

## Next Recommended Task

Implement notifications and reminders for appointments, treatment follow-ups, and clinic actions.
