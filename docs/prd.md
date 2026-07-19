# Lappo Owner App PRD

## Product

Lappo is a private mobile companion for pet owners. Its center is the pet card: profile data, photos, owner-entered medical history, documents, medications, feeding, events, reminders, announcements, and transfers.

## Primary User

The only supported product role is `pet_owner`.

Pet owners can:

- manage their own profile;
- create and edit pets;
- maintain self-reported visit records;
- store private documents and photos;
- track medications, feeding, and important events;
- receive in-app and local reminders;
- publish and edit permitted announcements;
- transfer a pet or accept an incoming transfer;
- export their data and request account deletion.
- use Free, Pro, or Pro+ owner plans;
- purchase additional standard or promoted announcement publications.

## Access Rules

- A user can access only pets they own or were explicitly granted access to.
- Medical records and documents are private.
- Announcement contact details are exposed only as required by the announcement flow.
- RLS and private storage policies enforce access on the backend.

## Explicitly Out Of Scope

- clinic administration;
- clinic, doctor, or receptionist accounts;
- doctor schedules and online appointment booking;
- clinic-created visit records;
- clinic and doctor reviews;
- clinic subscriptions and billing;
- chat, AI diagnosis, insurance, and telemedicine.

## Plans And Monetization

- `Free`: up to 3 pets and 1 standard personal announcement per calendar
  month across breeding and puppy-sale categories.
- `Pro`: up to 5 pets, 3 breeding announcements, and 3 puppy-sale
  announcements per billing month.
- `Pro+`: up to 50 pets, 20 breeding announcements, and 20 puppy-sale
  announcements per billing month.
- Events are free for every plan and do not consume announcement quotas.
- Services and offers are commercial publications and require a one-time
  announcement purchase.
- Extra announcement tiers are Standard (30 days), Top 7 (30 days with 7
  promoted days and 3 raises), and Top 15 (30 days with 15 promoted days and
  5 raises).
- Announcements stop being public after 30 days and are permanently deleted
  60 days after publication unless the owner deletes them sooner.
- Store purchases and entitlements are verified by the backend. The mobile
  client is never the source of truth for paid access.
- Pro prices are 79 UAH monthly and 799 UAH yearly. Pro+ prices are 499 UAH
  monthly and 4,999 UAH yearly. Eligible new subscribers may receive a
  one-time introductory month at 39 UAH for Pro or 249 UAH for Pro+.

## Internal Administration

- The platform may have a separate private web console for aggregate product,
  city, pet, announcement, subscription, and revenue analytics.
- The console is an internal platform tool, not a clinic or doctor workspace.
- Analytics access is role-based and audited.
- Medical records and private documents are excluded from general analytics.

## Product Principles

- Keep the pet card central.
- Let owners record information quickly without pretending that Lappo provides medical advice.
- Use calm Ukrainian copy and clear empty/error states.
- Keep sensitive data private by default.
- Prefer reliable owner workflows over marketplace complexity.

## Success Criteria

- A new owner can sign in, create a pet, add a medical record, attach a document, and set care reminders without assistance.
- Changes appear immediately across relevant screens.
- Owner data cannot be read or changed by another account.
- TestFlight builds pass analysis, automated tests, and critical device scenarios.
