# Lappo — App Store release checklist

## Release identity

- App name: `Lappo`
- Version: `1.0.0`
- Build: start with `1` and increase it for every upload
- Candidate Bundle ID: `com.lappo.app`
- Minimum iOS version: `13.0`
- OAuth callback: `lappo://auth/callback`

Confirm that `com.lappo.app` is available in the Apple Developer account before the first upload. The Bundle ID cannot be changed for an existing App Store Connect record.

## Supabase production setup

1. Back up the production database.
2. Apply all files in `supabase/migrations` in timestamp order. The release migration is `20260714010000_mobile_release_foundation.sql`.
3. Verify that the `pet-documents` bucket is private.
4. In Authentication → URL Configuration, add `lappo://auth/callback` to Redirect URLs.
5. Configure Google and Apple providers only if their buttons remain visible in the release build.
6. Test with two real test users:
   - each user sees only their own pets;
   - private photos cannot be opened with a permanent public URL;
   - ownership transfer appears only for the intended recipient;
   - accepting a transfer removes access from the previous owner;
   - an account deletion request appears in `account_deletion_requests`.
7. Define an internal process that completes account deletion requests within 30 days and documents any legally required retention.

The repository is not currently linked to the Supabase CLI on this computer, so the migration must be reviewed and applied through the Supabase SQL Editor or from a linked development machine. Apply it to a staging project first.

## Apple Developer and Supabase OAuth

1. Create an explicit App ID for `com.lappo.app`.
2. Create the App Store Connect app record with the same Bundle ID.
3. For Sign in with Apple, configure the Apple provider in Supabase with the correct Team ID, Key ID, private key, and Service ID settings.
4. Add the Supabase callback URL shown in the Supabase Apple provider settings to the Apple Service ID configuration.
5. Confirm that Google OAuth also allows the Supabase callback URL shown in the provider settings.
6. Test Google and Apple sign-in on a physical iPhone; simulator-only verification is not enough.

## Build on a Mac

Use the current stable Flutter SDK and Xcode 26 or later.

```sh
cd apps/mobile
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
flutter analyze
flutter test
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Open `ios/Runner.xcworkspace` when signing or archiving in Xcode. Select the correct Team, use automatic signing, and verify that the Release configuration uses `com.lappo.app`.

Never place the Supabase service-role key in the app. The anon key is expected in a client app; Row Level Security remains the security boundary.

## Device acceptance test

- Fresh install and first launch
- Email registration, email verification, login, logout, password reset
- Sign in with Apple and Google
- Add, edit, delete, and reopen a pet
- Avatar and passport upload from Camera and Photos
- Medication, feeding, and achievement create/edit/delete flows
- Clinic-authored visit record and private document viewing
- Ownership transfer between two accounts
- Poor network, airplane mode, expired session, and relaunch
- Account deletion request
- Permission denial for Camera and Photos
- All screens on a small supported iPhone and a current large iPhone
- No demo users, placeholder personal data, debug banners, or mock content in the release build

## App Store Connect

- Publish the privacy policy from `docs/privacy-policy-uk.md` at a public HTTPS URL.
- Provide a working public Support URL and monitored support email.
- Complete App Privacy using the actual production behavior, including Supabase and OAuth providers.
- Expected linked data categories: name, email address, phone number, user ID, photos/videos, and other user content.
- Tracking: No, provided no analytics or advertising SDK is added before submission.
- Add screenshots captured from the production-connected build, not mock mode.
- Complete age rating, content rights, encryption/export-compliance, category, copyright, review contact, and review notes.
- In review notes, explain that veterinary records belong to pets, files are private, and test credentials are supplied if registration or email verification prevents review.
- Upload through Xcode Organizer or Transporter, select the build, complete compliance questions, submit for review, and keep the release manual until review succeeds.

## Do not enable for version 1.0

The announcements marketplace remains unavailable in the Supabase-backed release until content filtering, reporting, blocking, moderation response, contact information, and a production backend are implemented. The mock implementation is retained for development only.
