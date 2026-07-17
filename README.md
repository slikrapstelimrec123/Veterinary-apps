# Lappo

Lappo is a Flutter mobile application for pet owners. It keeps pet profiles, owner-managed medical history, medications, feeding records, events, documents, reminders, announcements, and pet transfers in one private account.

## Product Scope

The current product has one application surface:

- `apps/mobile` — Flutter app for iOS and Android.

The discontinued clinic administration panel, doctor workflows, online appointment booking, clinic reviews, and clinic subscriptions are not part of the product.

Historical Supabase migrations retain the old schema so existing databases can be upgraded safely. The latest retirement migration revokes application-role access to legacy clinic tables without deleting historical data.

## Local Mobile Setup

```powershell
cd apps/mobile
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Never place a `service_role` key in the mobile app.

## Database

Apply all migrations in order:

```powershell
supabase db push
```

For local development:

```powershell
supabase start
supabase db reset
```

The local seed expects a fake `demo.pet.owner@example.com` Auth user and creates only owner-side demo data.

## Quality Checks

```powershell
cd apps/mobile
flutter analyze
flutter test
```

Before a TestFlight upload, also validate authentication, RLS, private files, owner-created medical records, data export, account deletion, announcements, and notifications against the connected Supabase project.

## Release

Codemagic builds from `codex/testflight-prep` using `codemagic.yaml`. Supabase values are supplied through the protected `lappo_supabase` environment group.
