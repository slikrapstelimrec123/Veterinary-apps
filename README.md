# Veterinary Clinics Platform

Premium MVP platform for veterinary clinics, veterinarians, and pet owners.

The product helps clinics manage profiles, doctors, services, schedules, appointments, clients, pets, visit records, medical documents, reviews, clinic subscription limits, and in-app notifications. Pet owners can create pet profiles, book appointments, receive updates, and keep treatment history in one trusted place.

## Tech Stack

- **Pet owner mobile app**: Flutter
- **Clinic admin panel**: Next.js, TypeScript
- **Backend**: Supabase Auth, PostgreSQL, Storage, Row Level Security
- **Future payments**: Stripe or local provider for clinics; Apple/Google subscriptions only if a later client premium plan is justified

Real payments, chat, push notifications, AI features, and complex marketplace logic are intentionally outside the first scaffold.

## Repository Structure

```text
apps/
  mobile/          Flutter app for pet owners
  admin/           Next.js admin panel for veterinary clinics
docs/              Product and technical documentation
supabase/
  migrations/      Database migrations
  policies/        Draft Row Level Security policies
  seed/            Seed data
```

## Environment Variables

Copy `.env.example` files and fill values locally. Never commit real secrets.

Root:

```bash
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

Admin:

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

Mobile:

```bash
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

For Flutter, pass values with `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Local Setup

Prerequisites:

- Flutter SDK
- Node.js 20+
- Supabase CLI

Install admin dependencies:

```bash
cd apps/admin
npm install
```

Prepare Flutter app:

```bash
cd apps/mobile
flutter pub get
```

## Run Mobile App

```bash
cd apps/mobile
flutter run
```

The mobile app supports Supabase-backed pet profiles and a local mock preview mode for UI work without backend credentials.

## Preview Mobile App UI Locally

The mobile app supports mock preview mode when Supabase environment values are missing or when `MOCK_MODE=true`.

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome --dart-define=MOCK_MODE=true
```

Mock mode includes:

- 2 pets
- 3 clinics
- 5 doctors
- 8 services
- Doctor schedules and generated available booking slots
- 2 owner appointments
- 3 visit records, including one owner-hidden draft
- 3 document metadata examples, including one owner-hidden internal document
- published review/rating examples
- one clinic that is temporarily unavailable for online booking
- notification inbox examples and notification preferences

With Supabase:

```bash
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Pet owner mobile routes currently support home, pet list, add/edit pet, pet profile, treatment history, visit details, private document metadata, clinic discovery, doctor profiles, appointment booking, owner appointment details/cancellation, settings, and logout.

## Run Admin Panel

```bash
cd apps/admin
npm run dev
```

Open `http://localhost:3000`.

The admin panel includes Supabase-backed authentication and clinic management modules for profile, services, doctors, schedules, appointment management, visit records, private visit documents, reviews, subscription limits, and notifications.

Auth routes:

- `/login`
- `/register-clinic`
- `/forgot-password`

Clinic dashboard routes are protected by middleware. `pet_owner` users are blocked from the clinic admin area.

## Apply Supabase Migrations

With Supabase CLI configured:

```bash
supabase db push
```

For local development:

```bash
supabase start
supabase db reset
```

Migration files live in `supabase/migrations`.

RLS policy reference files also live in `supabase/policies`.

## Create Accounts

Pet owner:

1. Configure mobile Supabase env values.
2. Run the Flutter app.
3. Use `Create pet owner account`.

Clinic owner:

1. Configure `apps/admin/.env.example` values in a local `.env`.
2. Run the admin panel.
3. Open `/register-clinic`.
4. Submit owner and clinic details.

The clinic owner flow creates a `profiles` row, a draft `clinics` row, and an active `clinic_members` row.

## Test Clinic Admin Features

After creating a clinic owner account and applying migrations:

1. Open `/dashboard` to view clinic status, doctors, services, and profile completion.
2. Open `/clinic/profile` to edit clinic name, city, address, contacts, logo URL, and publication state.
3. Open `/clinic/services` to add, edit, deactivate, or delete services.
4. Open `/clinic/doctors` to add, edit, deactivate, or delete doctors.
5. Open `/clinic/schedule` to add weekly doctor availability.
6. Open `/clinic/appointments` to review bookings, confirm/cancel/complete/no-show appointments, and assign doctors.
7. Open an appointment and create a visit record.
8. Open `/clinic/visit-records` to edit, publish, archive, and attach private documents.
9. Open `/clinic/subscription` to review the current plan, usage, and upgrade state.

This stage includes visit record creation from appointments, private document attachments, reviews after completed appointments, and manual subscription limits. It does not include real payments, chat, push notifications, or advanced marketplace ranking.

## Clinic Subscriptions And Limits

After applying migrations:

1. Open `/clinic/subscription` to see current plan, status, usage, and limits.
2. Open `/clinic/subscription/plans` to view Free, Basic, Pro, and Enterprise.
3. Click `Запросити апгрейд` to create a mock upgrade request.
4. Sign in as `platform_admin` and open `/platform/subscription-requests`.
5. Approve the request to manually activate the requested plan.

Implemented checks:

- adding doctors;
- adding services;
- confirming appointments;
- creating visit records;
- uploading visit documents;
- publishing a clinic profile;
- mobile online booking availability.

No card data is collected and no payment provider is connected.

## Notifications And Reminders

Mobile mock mode:

1. Open the `Сповіщення` tab.
2. Review unread/read notification examples.
3. Tap a notification to open the related appointment or visit record.
4. Use the check icon to mark all notifications as read.
5. Open Settings → `Сповіщення` to update preferences locally.

Real Supabase mode:

1. Apply `20260630210000_notifications_reminders_module.sql`.
2. Confirm RLS policies from `008_notifications_reminders_policies.sql`.
3. Create an appointment from mobile to notify clinic owner/manager.
4. Confirm/cancel/complete appointments in admin to notify the pet owner.
5. Publish a visit record or upload an owner-visible document to notify the pet owner.
6. Submit a review to notify clinic owner/manager.
7. Open `/clinic/notifications` and `/clinic/settings/notifications` in the admin panel.

Real email, SMS, and push providers are not connected in this stage.

## Beta Readiness

Beta support files:

- `docs/demo-accounts.md`
- `docs/beta-qa-checklist.md`
- `docs/beta-release-notes.md`
- `docs/security-beta-audit.md`
- `docs/known-limitations.md`

Admin trust/support pages:

- `/privacy`
- `/terms`
- `/data-processing`
- `/support`

Mobile settings include privacy, terms, beta feedback, data export placeholder, and account deletion placeholder.

## Demo Data

Create fake Supabase Auth users first:

- `demo.pet.owner@example.com`
- `demo.clinic.owner@example.com`
- `demo.vet@example.com`
- `demo.manager@example.com`
- `demo.platform.admin@example.com`

Do not commit real passwords.

Then run:

```bash
supabase db reset
```

or, after migrations are already applied, seed manually with your local database connection:

```bash
psql "$SUPABASE_DB_URL" -f supabase/seed/seed.sql
```

The seed creates fake clinic data, doctors, services, schedules, pets, appointments, visit records, document metadata, reviews, notifications, and subscription state.

## Troubleshooting

- If `next` is not recognized, run `npm install` inside `apps/admin`.
- If `flutter` or `dart` is not recognized, install Flutter SDK and add it to PATH.
- If mobile opens mock data unexpectedly, provide `SUPABASE_URL` and `SUPABASE_ANON_KEY`, or set `MOCK_MODE=false`.
- If Git says `not a git repository`, first run `cd "C:\Users\slikr\Desktop\Project IT\Приложение для ветклиник"`.

## Reviews And Ratings

Mobile mock mode:

1. Open a completed appointment that has no review.
2. Tap `Залишити відгук`.
3. Select a 1-5 star rating, optionally add doctor/service ratings and a comment.
4. Submit and confirm the thank-you screen.
5. Open a clinic or doctor profile to see published rating summaries and review cards.

Real Supabase mode:

1. Apply the reviews migration `20260630183000_reviews_ratings_module.sql`.
2. Confirm RLS policies from `006_reviews_ratings_policies.sql`.
3. Complete an appointment or publish a visit record connected to the appointment.
4. Sign in as the pet owner and submit one review for that appointment.
5. Open `/clinic/reviews` in the clinic cabinet to view the review context.
6. Use `/platform/reviews` as the basic platform moderation placeholder.

## Test Visit Records And Documents

After applying migrations:

1. Open `/clinic/appointments`.
2. Open a confirmed or completed appointment.
3. Use `Створити запис в медкартці`.
4. Save as draft or publish to the pet owner.
5. Open `/clinic/visit-records` to view and edit the record.
6. On the record detail page, upload a PDF/JPG/PNG/HEIC document to the private `visit-documents` bucket.
7. In the mobile app, open the pet profile, treatment history, and record details. Only published records and owner-visible documents should appear.

## Development Stages

1. Project setup and documentation.
2. Authentication, user profiles, roles, and database.
3. Clinic admin panel: clinic profile, doctors, services, schedules.
4. Pet owner mobile app: pets, clinics, profiles.
5. Appointment booking and appointment management.
6. Visit records and private document uploads.
7. Beta testing with 5-10 veterinary clinics.

## Next Recommended Task

Prepare the MVP for beta testing: onboarding, demo accounts, QA checklist, privacy pages, terms, and release readiness.
