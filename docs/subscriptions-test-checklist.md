# Subscriptions Test Checklist

## Clinic Owner

- Clinic owner can open `/clinic/subscription`.
- Clinic owner can see current plan, status, usage, and limits.
- Clinic owner can open `/clinic/subscription/plans`.
- Clinic owner can request Basic, Pro, or Enterprise.
- Clinic owner sees a success message after creating an upgrade request.
- Clinic owner sees a pending state and cannot create duplicate pending requests.

## Permissions

- Veterinarian cannot manage subscription.
- Pet owner cannot access subscription, usage, or upgrade request data.
- Public user can read only active public plans.
- Clinic owner cannot read another clinic's subscription or usage.
- Platform admin can view subscription requests.
- Platform admin can approve a pending request.
- Platform admin can reject a pending request.

## Limits

- Clinic cannot add a doctor after reaching `max_doctors`.
- Clinic cannot add a service after reaching `max_services`.
- Clinic cannot confirm appointments after reaching monthly appointment limit.
- Clinic cannot create a visit record after reaching `max_visit_records`.
- Clinic cannot upload a document after reaching `max_documents`.
- Clinic cannot upload a document when storage would exceed `max_storage_mb`.
- Clinic cannot publish a profile if `can_publish_clinic_profile` is false.
- Existing clinic data remains visible after a downgrade or limit reduction.

## Mobile

- Mobile mock mode includes one normal clinic that accepts booking.
- Mobile mock mode includes one clinic unavailable for online booking.
- Pet owner sees only `Ця клініка тимчасово недоступна для онлайн-запису.` for unavailable clinic.
- Pet owner does not see clinic plan, billing status, payment issue, or internal subscription details.

## Real Payment Safety

- No card fields exist in the admin UI.
- No Stripe, LiqPay, WayForPay, Fondy, Apple Billing, or Google Billing integration exists.
- No service role key is exposed to admin or mobile frontend.
