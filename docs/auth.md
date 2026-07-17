# Authentication

The supported application role is `pet_owner`.

## Methods

- email and password;
- Google OAuth;
- Sign in with Apple.

OAuth returns to the `com.lappo.app://login-callback` deep link. Supabase URL allow-lists and provider callback URLs must match the production configuration.

## Profile Bootstrap

After authentication, the backend creates or updates the matching `profiles` row. The mobile app accepts `pet_owner`; legacy roles receive an unsupported-account message and cannot enter owner features.

## Rules

- Never bundle `service_role`.
- Treat the anon key as public configuration, not authorization.
- RLS must validate every data operation with `auth.uid()`.
- Password reset and OAuth callbacks must use approved deep links.
