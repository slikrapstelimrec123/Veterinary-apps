# Veterinary Clinics Platform

Premium MVP platform for veterinary clinics, veterinarians, and pet owners.

The product helps clinics manage profiles, doctors, services, schedules, appointments, clients, pets, visit records, and medical documents. Pet owners can create pet profiles, book appointments, and keep treatment history in one trusted place.

## Tech Stack

- **Pet owner mobile app**: Flutter
- **Clinic admin panel**: Next.js, TypeScript
- **Backend**: Supabase Auth, PostgreSQL, Storage, Row Level Security
- **Future payments**: Stripe or local provider for clinics; Apple/Google subscriptions only if a later client premium plan is justified

Payments, chat, push notifications, AI features, and complex marketplace logic are intentionally outside the first scaffold.

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

The admin panel includes Supabase-backed authentication and clinic management modules for profile, services, doctors, schedules, appointment management, visit records, and private visit documents.

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

This stage includes visit record creation from appointments and private document attachments. It does not include payments, reviews, chat, push notifications, or advanced marketplace features.

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

Implement reviews, clinic ratings, doctor ratings, and post-appointment feedback.
