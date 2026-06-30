# Security And Privacy

## Principles

- Supabase Row Level Security is the source of truth.
- Frontend route guards improve UX but do not replace RLS.
- Medical records and documents are private by default.
- Never expose `SUPABASE_SERVICE_ROLE_KEY` to the mobile app or admin frontend.
- Public users can see only published clinic, doctor, and service profiles.

## Profiles

Users can read and update their own profile.

Platform admins can read profiles for support and moderation.

Clinic members can read profiles connected to their clinic only when needed for clinic workflows.

## Clinics

Public users can read clinics only when `status = published` and `published = true`.

Clinic owners and clinic managers can update their own clinic profile.

Clinic members can read their clinic.

Platform admins can read and update clinics for moderation.

## Services

Clinic members can read services for their clinic.

Clinic owners and clinic managers can create, update, deactivate, archive, or delete services when safe.

Veterinarians can read clinic services but cannot manage the service catalog.

Public users can read only `active` and `is_public` services from published clinics.

## Doctors

Clinic members can read doctors for their clinic.

Clinic owners and clinic managers can create, update, deactivate, archive, or delete doctors when safe.

Veterinarians can read their own linked doctor profile and schedules.

Public users can read only `active` and `is_public` doctors from published clinics.

## Doctor Schedules

Clinic members can read schedules for their clinic.

Clinic owners and clinic managers can create, update, and delete schedule rows.

Veterinarians can read their own linked schedules.

Public users can read only active schedules for active public doctors in published clinics. Clinic-only schedules for non-public doctors remain private.

## Clinic Members

Clinic owners can manage members of their clinic.

Clinic members can read active members of their clinic.

Future invitation flow should use `status = invited` before activation.

## Pets

Pet owners can read and update only their own pets.

Pet owners can create pet profiles and then create ownership links in `pet_owners`.

Clinic members can read pets only when the pet is connected to an appointment or visit record in their clinic.

Platform admin access should be reserved for support and audited later.

## Appointments

Pet owners can create pending appointments only for pets they own, published clinics, active public services, and active public doctors.

Pet owners can read their own appointments.

Pet owners can cancel their own pending or confirmed appointments.

Clinic owners and clinic managers can read appointments for their clinic.

Clinic owners and clinic managers can confirm, cancel, complete, mark no-show, assign doctors, and add clinic notes.

Veterinarians can read appointments assigned to them.

## Visit Records

Clinic medical staff can create visit records for their clinic.

Veterinarians can create records for appointments assigned to them or connected to their clinic according to RLS checks.

Pet owners can read published records connected to their own pets.

Pet owners cannot create or edit clinic visit records.

`internal_notes` must not be shown in owner-facing UI.

Draft and archived records are clinic-only.

## Documents

Visit documents are not public.

The database stores metadata in `visit_documents`.

Files should live in the private Supabase Storage bucket `visit-documents`.

Signed URLs should be created only after checking database access.

The mobile app can request a short-lived signed URL for owner-visible documents only. It does not expose public file URLs.

## Reviews And Anti-Fake Rules

Reviews are protected by Row Level Security plus database constraints.

Pet owners can create reviews only for their own appointment, their own pet, and only after the appointment is completed or a linked visit record is published.

One appointment can receive only one owner review.

Review inserts are checked against appointment owner, clinic, pet, doctor, and optional visit record relationships.

Public users can read only `published` reviews.

Clinic members can view reviews for their own clinic but cannot edit or delete owner review content.

Platform admins can change moderation status.

Hidden, reported, pending, and removed reviews are excluded from public clinic/doctor rating summaries.

## Clinic Subscriptions

Subscription data is clinic-private.

Public and logged-in users can read only active public plan definitions from `subscription_plans`.

Clinic owners and clinic managers can read their clinic subscription and usage. Veterinarians cannot manage subscription. Pet owners cannot access clinic subscription, usage, upgrade requests, provider IDs, or billing state.

Clinic owners can create upgrade requests only for their own clinic. Platform admins can read and update all subscription requests and manually activate a plan.

Plan limits are enforced server-side and through database helper functions. UI prompts are guidance only and do not replace RLS or server checks.

Pet owners see only a generic online-booking unavailable message when a clinic cannot accept bookings. Billing or subscription reasons are never exposed in the mobile app.

## Notifications

Notifications are private per recipient.

Users can read and update only notifications where `recipient_user_id = auth.uid()`. Clinic members cannot read a pet owner's inbox unless a separate notification is addressed directly to that clinic user.

Notification bodies must avoid sensitive medical details. Use generic copy such as `Додано запис лікування` instead of diagnosis text. Document URLs are never stored in notification bodies.

Notification preferences are user-owned. Users can read and update only their own preferences. Marketing notifications are disabled by default.

Delivery logs are not exposed to regular users. Platform admins can inspect them later for support.

Scheduled notifications are readable only by the recipient and platform admin. Processing pending reminders should happen later through a trusted backend job or Edge Function.

## Beta Feedback

Users can create feedback only as themselves. Users can read their own feedback. Platform admins can read and manage all beta feedback.

Feedback should not include real sensitive medical details during local demo testing. Beta testers should describe issues without copying full diagnoses or private document contents.

## Current Test Checklist

- Pet owner cannot read another owner's pets.
- Pet owner cannot access clinic admin pages.
- Clinic owner can access own dashboard.
- Clinic owner can update clinic profile.
- Clinic owner can add and edit services.
- Clinic owner can add and edit doctors.
- Clinic owner can create doctor schedules.
- Veterinarian can view own schedule without catalog management actions.
- Clinic owner cannot access another clinic's data.
- Veterinarian cannot manage subscription.
- Pet owner cannot access clinic subscription or usage data.
- Clinic cannot create doctors, services, appointment confirmations, visit records, or document uploads after relevant plan limits are reached.
- User cannot read another user's notification inbox.
- User can mark only own notifications as read.
- Marketing notifications are disabled by default.
- Beta feedback can be created only by the signed-in user.
- Public user can read only published clinics, doctors, and services.
- Public user can read only active public subscription plans.
- Visit documents cannot be opened without authorized signed URL.
