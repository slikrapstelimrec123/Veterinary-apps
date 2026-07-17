# Notifications

Lappo uses two owner-facing channels:

- in-app notifications stored in Supabase;
- local device notifications for care reminders.

Notifications must contain generic wording and must not expose diagnoses, treatment details, or private document URLs.

Supported owner events include medical record updates, document availability, medication reminders, important events, announcements, and pet-transfer requests.

The app requests system permission during first-run owner onboarding. Notification preferences must be private to the authenticated user.
