# Database Scope

Active owner-side data includes:

- `profiles`;
- `pets` and `pet_owners`;
- `visit_records` and `visit_documents`;
- `pet_medications`, `pet_feedings`, and `pet_achievements`;
- `notifications` and `notification_preferences`;
- `announcements` and announcement photo metadata;
- `pet_transfers`;
- `beta_feedback` and account-deletion requests.

Medical visit records use `provider_name` as optional owner-entered text and must keep `clinic_id`, `doctor_id`, and `appointment_id` null.

Historical migrations still create discontinued clinic, booking, review, and subscription tables so existing environments can upgrade without rewriting migration history. `20260717010000_retire_clinic_booking_surfaces.sql` revokes access to those tables from `anon` and `authenticated`.

RLS and private Storage policies remain the source of truth for owner isolation.
