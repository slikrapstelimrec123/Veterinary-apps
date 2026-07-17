# Security Model

## Trust Boundary

The Flutter client is untrusted. Supabase RLS, constrained RPCs, and private Storage policies enforce authorization.

## Owner Isolation

- Every owner record is checked against `auth.uid()`.
- Pet-scoped records require confirmed pet ownership.
- Medical files remain in private buckets and use short-lived signed access.
- Public announcement fields are separated from private medical content.

## Credentials

- Mobile builds contain only Supabase URL and anon key.
- `service_role`, Apple private keys, signing certificates, and provider secrets stay outside source control.
- OAuth callbacks and deep links are allow-listed.

## Legacy Surface

Clinic administration, booking, reviews, and clinic subscriptions are discontinued. Their historical tables are retained for migration compatibility but access is revoked from `anon` and `authenticated`.

## Release Checks

- scan source and build logs for secrets;
- test cross-account access;
- test private file URLs after session expiry;
- verify account deletion and export;
- review dependency and platform privacy declarations.
