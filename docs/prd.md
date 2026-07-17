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
- payments, chat, AI diagnosis, insurance, and telemedicine.

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
