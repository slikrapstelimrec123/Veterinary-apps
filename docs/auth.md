# Authentication And Roles

## Provider

The MVP uses Supabase Auth with email and password.

Not included yet:

- social login
- phone login
- passwordless login
- invitation email flow

## Roles

User roles are stored in `profiles.role`.

Allowed values:

- `pet_owner`
- `clinic_owner`
- `veterinarian`
- `clinic_manager`
- `platform_admin`

Users must not be allowed to choose `platform_admin` during public registration.

## Pet Owner Registration

Surface: Flutter mobile app.

Flow:

1. User creates account with email, password, and full name.
2. Supabase Auth creates `auth.users` row.
3. App creates `profiles` row with `role = pet_owner`.
4. User is routed to the pet owner mobile home.

Pet owners can:

- edit own profile
- create pets linked to their account
- view own pets
- book appointments for own pets
- view completed visit records and visible documents for own pets

## Clinic Owner Registration

Surface: Next.js admin panel at `/register-clinic`.

Flow:

1. Clinic owner enters full name, clinic name, email, and password.
2. Supabase Auth creates account.
3. Admin app creates `profiles` row with `role = clinic_owner`.
4. Admin app creates `clinics` row with `status = draft`.
5. Admin app creates `clinic_members` row with:
   - `role = clinic_owner`
   - `status = active`
6. Owner is routed to `/dashboard`.

Clinic owners can:

- manage own clinic profile
- manage members later
- manage doctors, services, schedules, appointments, and visit records

## Veterinarian And Clinic Manager

The database supports these roles now, but the invitation flow is not implemented yet.

Future flow:

1. Clinic owner invites staff member.
2. `clinic_members` row is created with `status = invited`.
3. User accepts invite and creates account.
4. Membership becomes `active`.

## Admin Panel Access

Allowed roles:

- `clinic_owner`
- `veterinarian`
- `clinic_manager`
- `platform_admin`

Blocked role:

- `pet_owner`

Middleware protects admin routes and redirects unauthenticated users to `/login`.

## Mobile Access

The mobile MVP is for `pet_owner` users.

Clinic roles can sign in but see a message explaining that clinic management is available in the web admin panel.

`platform_admin` users should not use the mobile MVP interface.

## Helper Utilities

Next.js:

- `getCurrentUser()`
- `getCurrentProfile()`
- `requireAuth()`
- `requireClinicRole()`
- `requireClinicAccess()`

Flutter:

- `AuthRepository`
- `AuthState`
- `CurrentUser`
- `AuthGate`

PostgreSQL:

- `is_platform_admin()`
- `is_clinic_member(clinic_id)`
- `has_clinic_role(clinic_id, roles)`
- `owns_pet(pet_id)`
- `can_access_visit_record(visit_record_id)`

