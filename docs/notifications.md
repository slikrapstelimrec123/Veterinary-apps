# Notifications And Reminders

This MVP implements in-app notifications, preferences, scheduled reminder records, and provider-ready architecture.

No real SMS, email, or push provider is connected yet.

## Notification Types

Pet owner types:

- `appointment_created`
- `appointment_confirmed`
- `appointment_cancelled_by_clinic`
- `appointment_reminder_24h`
- `appointment_reminder_2h`
- `visit_record_published`
- `document_uploaded`
- `next_visit_recommended`
- `review_request`
- `clinic_message_placeholder`

Clinic user types:

- `new_appointment_request`
- `appointment_cancelled_by_owner`
- `appointment_upcoming_today`
- `visit_record_missing`
- `review_received`
- `subscription_limit_warning`
- `subscription_upgrade_request_status`

## Channels

Implemented:

- `in_app`

Prepared for later:

- `email`
- `push`
- `sms`

Provider keys must never be hardcoded. Future delivery should happen through trusted backend code, Edge Functions, or scheduled jobs.

## Preferences

Default preferences:

- in-app enabled;
- appointment reminders enabled;
- treatment updates enabled;
- review requests enabled;
- clinic operational alerts enabled;
- marketing disabled.

Marketing remains disabled in MVP.

## Event Generation

Database triggers create notifications for:

- new appointment requests;
- appointment confirmation;
- clinic cancellation;
- owner cancellation;
- appointment completion review requests;
- published visit records;
- owner-visible document uploads;
- received reviews;
- subscription upgrade request approval or rejection.

Admin server actions create subscription limit warning notifications through a narrow clinic-member-only RPC.

## Scheduled Reminders

When an appointment is confirmed, pending reminders are created:

- 24 hours before appointment;
- 2 hours before appointment.

When an appointment is cancelled or completed, pending reminders are cancelled.

No background worker is implemented yet. A future cron or Supabase Edge Function should process `scheduled_notifications.status = pending` and create/send notifications at `scheduled_for`.

## Privacy Rules

Notification body text must stay generic:

- OK: `Клініка додала новий запис до медичної історії вашої тварини.`
- Not OK: full diagnosis, treatment details, document URLs, internal clinic notes.

Pet owners can see only notifications addressed to them.

Clinic users can see only notifications addressed to their own user account.

Delivery logs are for platform/admin support only.
