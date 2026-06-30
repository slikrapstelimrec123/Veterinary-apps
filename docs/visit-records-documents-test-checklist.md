# Visit Records And Documents Test Checklist

## Clinic Admin

- Clinic owner can open an appointment and create a visit record.
- Clinic manager can create a basic visit record if current permissions allow it.
- Veterinarian can create a visit record for an assigned appointment.
- Draft record is visible in `/clinic/visit-records` for clinic staff.
- Published record is visible to the pet owner in mobile treatment history.
- Archived record is not owner-visible.
- Internal notes are visible in admin details and edit screens.
- Internal notes are not returned or rendered in mobile pet owner screens.
- Appointment detail shows `Create visit record` when no record exists.
- Appointment detail shows `View visit record` when a record exists.

## Documents

- Clinic staff can upload PDF/JPG/PNG/HEIC documents up to 10 MB.
- Uploaded file path follows `clinic_id/pet_id/visit_record_id/file_name`.
- Private bucket is `visit-documents`.
- Visible documents appear in mobile treatment history/details.
- Hidden/internal documents do not appear in mobile.
- Pet owner document tap requests a signed URL instead of using a public URL.
- Raw storage paths are not shown as public download links.

## Security

- Pet owner cannot create, edit, or upload visit records/documents.
- Pet owner cannot view draft visit records.
- Pet owner cannot view another user's pet records.
- Clinic user cannot access another clinic's records.
- Veterinarian cannot edit unrelated clinic records.
- Platform admin functionality is not overbuilt in this stage.

## Out Of Scope

- Payments.
- Subscriptions.
- Reviews and ratings.
- Chat.
- Push notifications.
- AI diagnosis or generated medical advice.
