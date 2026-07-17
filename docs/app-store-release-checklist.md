# Lappo App Store Release Checklist

## Identity

- App name: `Lappo`
- Bundle ID: `com.lappo.app`
- Version: `1.0.0`
- Increase the build number for every upload.
- OAuth deep link: `com.lappo.app://login-callback`

## Supabase

- Back up the database.
- Apply all migrations in timestamp order.
- Confirm the final legacy-surface retirement migration is applied.
- Keep medical buckets private.
- Test RLS with two unrelated owner accounts.
- Verify data export and account deletion.
- Verify Google and Apple callback and redirect allow-lists.

## Build

```sh
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=BUILD_NUMBER \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Never place the Supabase `service_role` key or provider secrets in the app.

## Device Acceptance

- fresh install and first-run notification permission;
- email, Google, and Apple authentication;
- create/edit/delete pet and avatar consistency;
- owner-created medical visits and private files;
- medication, feeding, and event persistence;
- notification inbox and alert sound;
- announcement creation/editing and immediate refresh;
- pet transfer between two accounts;
- data export and account deletion;
- poor network, expired session, and relaunch;
- small and large supported iPhones.

## App Store Connect

- Publish privacy and support pages at public HTTPS URLs.
- Complete App Privacy from actual production behavior.
- Add production-connected screenshots.
- Complete age rating, content rights, encryption compliance, category, review contact, and review notes.
- Provide reviewer credentials if account creation or verification would block review.
