# Lappo: handoff for a new Codex chat

Last updated: 2026-08-10 (Europe/Kyiv)

This file is the persistent project memory for continuing work in a fresh
Codex chat. Read it together with `AGENTS.md` and `docs/prd.md` before making
changes. `AGENTS.md` has priority if older code or documents disagree with it.

## How to resume

Start a new chat in the `C:\Users\slikr\Veterinary-apps` workspace and send:

> Continue work on Lappo. First read AGENTS.md, docs/project-handoff.md and
> docs/prd.md completely. Inspect the current branch and working tree before
> changing anything. Do not expose or hardcode secrets.

Then describe only the next requested change. There is no need to paste the
old conversation.

## Product direction

- Product: Lappo, a Flutter application for pet owners.
- Visible product language: Ukrainian.
- The pet medical card is the center of the product.
- Supported application role: `pet_owner`.
- Medical visits are created and maintained by owners themselves.
- Do not restore clinic administration, doctor accounts, online booking,
  clinic reviews, clinic subscriptions, chat, AI diagnosis, insurance, or
  telemedicine.
- Sensitive pet, medical, and document data must be owner-isolated through
  Supabase RLS and private storage policies.
- Public access is limited to deliberately published announcement data.
- UI direction: minimal, premium, calm, trustworthy, with obvious primary
  actions and confirmation for destructive operations.

The detailed current scope, plan limits, announcement rules, pricing concept,
and success criteria are in `docs/prd.md`.

## Repository and release branch

- Local workspace: `C:\Users\slikr\Veterinary-apps`
- GitHub: `https://github.com/slikrapstelimrec123/Veterinary-apps`
- Release/TestFlight branch: `codex/testflight-prep`
- Mobile application: `apps/mobile`
- Database migrations: `supabase/migrations`
- CI configuration: `codemagic.yaml`
- Before editing, always inspect `git status` and preserve unrelated user
  changes.

## Current verified release state

- Latest committed fix: `164fb3a Isolate local reminders between accounts`
- Latest successful Codemagic/TestFlight build: **51**
- Build 51 completed analysis, Flutter tests, signed IPA creation, and App
  Store Connect publishing successfully.
- The build was generated from `codex/testflight-prep` and commit `164fb3a`.
- The notification isolation fix namespaces scheduled local reminders by the
  authenticated account and clears the previous account's scheduled reminders
  when the session changes. This was added because one account received a
  reminder belonging to another account.

After every mobile code change intended for testers:

1. Run `flutter analyze` and `flutter test` in `apps/mobile`.
2. Commit only the intended changes.
3. Push `codex/testflight-prep`.
4. Codemagic automatically builds and publishes to App Store Connect.
5. Confirm the exact new build number in Codemagic and wait for Apple
   processing before asking testers to update through TestFlight.

## External services and identifiers

These are identifiers and locations, not credentials.

### Supabase

- Project reference: `krtjhmqiaelspjxtdfqu`
- Dashboard: `https://supabase.com/dashboard/project/krtjhmqiaelspjxtdfqu`
- Mobile builds receive `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the
  protected Codemagic environment group `lappo_supabase`.
- Never put a Supabase `service_role` key in the app, repository, screenshots,
  chat, or client-side web code.
- Apply database changes as versioned migrations; keep RLS as the source of
  truth and verify changes with two separate user accounts.

### Apple / App Store Connect

- App name: Lappo
- App Store Connect app ID: `6790752960`
- Bundle identifier: `com.lappo.app`
- Distribution is configured through the Codemagic App Store Connect
  integration named `codemagic`.
- Sign in with Apple service configuration has been set up for the project.
- Signing certificates, profiles, API keys, bank/tax details, subscription
  metadata, screenshots, and review information remain in Apple's portals and
  must not be copied into this file.

### Codemagic

- Application ID: `6a56085b57e3046b1ca5db3d`
- Workflow: `lappo-ios-testflight`
- Workflow display name: `Lappo iOS - TestFlight & App Store`
- Trigger: push to `codex/testflight-prep`
- Protected environment group: `lappo_supabase`
- iOS build number is Codemagic's `$PROJECT_BUILD_NUMBER`.

### Google authentication

- Google OAuth is configured through Google Cloud and Supabase Auth.
- Client IDs and client secrets stay in Google Cloud/Supabase configuration;
  do not copy them into the repository or this handoff.
- OAuth callback/deep-link behavior must be tested on an installed TestFlight
  build, not only in a desktop browser.

### Internal analytics/admin site

- A separate internal admin site was created for platform analytics and user
  management. It is not a clinic panel and must not expose private medical
  records or documents.
- Its currently used hosted URL has been under the
  `lappo-admin.ivannashepetyuk.chatgpt.site` domain.
- Admin authorization is role-based (`platform_admin`) and must be enforced by
  the backend, not merely hidden in the UI.
- The primary intended administrator email is
  `slikrapstelimrec123@gmail.com`.
- Hosting sessions and passwords are not stored here. Re-authenticate through
  the relevant service when a new chat needs browser access.

## Secrets and access policy

- A new chat does not inherit passwords, private keys, browser cookies, or
  secrets from this conversation.
- Do not store passwords, Apple `.p8` keys, `.p12` passwords, Supabase service
  keys, OAuth client secrets, access tokens, or banking/tax data in Git.
- Use signed-in browser sessions when available, or ask the owner to sign in.
- Environment variables belong in Codemagic/Supabase/hosting secret stores.
- If a credential was pasted into chat or exposed publicly, rotate it rather
  than recording it in this file.

## Critical regression checks

Before a final release or after changing authentication, notifications, RLS,
transfers, or documents, test at least two unrelated accounts and confirm:

- account A cannot see account B's pets, medical records, files, counters, or
  reminders;
- local and push notifications contain only data owned by the receiving user;
- signing out clears or re-namespaces scheduled local reminders;
- tapping a notification opens only an accessible matching record and fails
  safely if the record is unavailable;
- private documents cannot be opened with a public URL;
- pet transfer changes ownership atomically and removes old-owner access;
- profile, pet, visit, medication, feeding, event, document, and announcement
  changes appear immediately;
- Google and Apple sign-in return to the app correctly;
- account deletion and data export work as documented;
- all plan and publication entitlements are verified by the backend if that
  functionality is in the tested release.

Use the checklists under `docs/`, especially:

- `docs/beta-qa-checklist.md`
- `docs/auth-test-checklist.md`
- `docs/notifications-test-checklist.md`
- `docs/visit-records-documents-test-checklist.md`
- `docs/app-store-release-checklist.md`
- `docs/security.md`

## Working style agreed with the owner

- Preserve the current working application while making focused changes.
- Diagnose from code, logs, migrations, and screenshots before changing data.
- Prefer safe migrations and reversible changes.
- Do not delete production users or records without an explicit, current
  request identifying exactly what should be removed.
- Run proportionate automated checks before pushing a build.
- Report the exact TestFlight build number after every successful release
  build.

