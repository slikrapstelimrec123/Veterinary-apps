# Security Beta Audit

## Checked

- Sensitive tables use Row Level Security.
- Pet ownership is enforced through `pet_owners`.
- Clinic access is scoped through `clinic_members`.
- Visit records expose published owner-facing records only.
- Internal notes are clinic-side UI only.
- Visit document metadata supports owner-visible and owner-hidden records.
- Reviews are tied to completed appointments or published visit records.
- Clinic users cannot edit owner review text directly.
- Subscription data is clinic-private and not owner-facing.
- Notifications are private per `recipient_user_id`.
- Beta feedback is owner-private and platform-admin manageable.
- Service role keys are not present in frontend/mobile examples.

## Safe For Controlled Beta

- Mock mode uses fake data.
- Demo seed uses fake emails and no committed passwords.
- Legal pages clearly say they are beta placeholders.
- Account deletion/export are placeholders and avoid unsafe destructive deletion.

## Needs Review Before Public Launch

- Full legal review of privacy, terms, and data processing text.
- Storage bucket policies and signed URL Edge Function flow.
- Background processing for scheduled reminders.
- Production backup and monitoring strategy.
- Audit logging for admin/platform actions.
- Formal RLS test suite.
- Data retention and deletion policy with clinics.
