# Notifications Test Checklist

## Mobile Pet Owner

- Pet owner sees unread badge in bottom navigation.
- Pet owner can open `Сповіщення`.
- Pet owner can mark one notification as read by opening it.
- Pet owner can mark all notifications as read.
- Appointment notification opens appointment details.
- Visit record notification opens visit record details.
- Review request notification opens appointment details with review action available.
- Pet owner can update notification preferences.
- Marketing notifications are disabled by default.

## Clinic Admin

- Clinic user sees recent notifications in the top notification card.
- Clinic user can open `/clinic/notifications`.
- Clinic user can mark one notification as read.
- Clinic user can mark all notifications as read.
- Clinic user can open `/clinic/settings/notifications`.
- Clinic user can update operational notification preferences.

## Event Generation

- Creating an appointment from mobile creates `new_appointment_request` for clinic owner/manager.
- Confirming an appointment creates `appointment_confirmed` for pet owner.
- Cancelling an appointment from clinic creates `appointment_cancelled_by_clinic` for pet owner.
- Cancelling an appointment from owner creates `appointment_cancelled_by_owner` for clinic owner/manager.
- Completing an appointment creates `review_request` for pet owner.
- Publishing a visit record creates `visit_record_published` for pet owner.
- Owner-visible document upload creates `document_uploaded` for pet owner.
- Owner-hidden document upload does not notify pet owner.
- Review insert creates `review_received` for clinic owner/manager.
- Subscription request approval or rejection creates `subscription_upgrade_request_status`.

## Reminders

- Confirming an appointment creates 24h and 2h pending scheduled reminders when times are in the future.
- Cancelling appointment cancels pending scheduled reminders.
- Completing appointment cancels pending scheduled reminders.

## Security

- User cannot read another user's notification inbox.
- User can update only own notification status.
- Clinic users cannot access pet owner notification inbox.
- Delivery logs are not visible to regular users.
- Notification bodies do not include diagnosis text, document URLs, or internal notes.
