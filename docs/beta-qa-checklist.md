# Beta QA Checklist

## Authentication And Roles

- Pet owner can register, log in, and log out.
- Clinic owner can register clinic, log in, and log out.
- Veterinarian reaches clinic workspace with limited permissions.
- Clinic manager reaches operational pages.
- Platform admin reaches platform placeholders.

## Pet Owner Flow

- Create pet profile.
- Browse published clinics.
- Open clinic profile.
- Open doctor profile.
- Book appointment.
- See appointment in `Мої записи`.
- Receive in-app notification after confirmation.
- View published visit record.
- View owner-visible document metadata.
- Leave review after completed appointment.
- Update notification preferences.
- Send beta feedback.

## Clinic Flow

- Complete clinic profile.
- Add services.
- Add doctors.
- Configure doctor schedule.
- Publish clinic profile.
- View new appointment request.
- Confirm appointment.
- Create and publish visit record.
- Upload owner-visible and owner-hidden document metadata.
- View review.
- View subscription usage.
- View notifications.
- Send beta feedback.

## Privacy And RLS

- Pet owner cannot see another owner's pets.
- Pet owner cannot see draft visit records.
- Pet owner cannot see internal notes.
- Pet owner cannot see hidden documents.
- Clinic cannot access another clinic's data.
- Notification inbox is private to recipient.
- Subscription data is not visible to pet owners.
- Reviews cannot be created without eligible completed appointment.
- Clinics cannot edit/delete owner review text directly.

## UI And States

- Major mobile screens have loading, empty, and error states.
- Major admin pages have empty states and status messages.
- Buttons and status labels are in Ukrainian.
- Beta disclaimer is visible but not alarming.

## Demo And Release

- Mock mode works without Supabase env values.
- Demo seed can be applied locally after creating fake auth users.
- Legal placeholders are linked.
- Known limitations are documented.
- No real payment, SMS, email, or push provider is connected.
