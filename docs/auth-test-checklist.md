# Auth Test Checklist

Use this checklist after Supabase environment values are configured.

## Pet Owner

- Create pet owner account in mobile app.
- Confirm `profiles.role = pet_owner`.
- Log out.
- Log in again.
- Confirm pet owner reaches mobile home.
- Confirm pet owner is redirected or blocked from admin panel.

## Clinic Owner

- Create clinic owner account at `/register-clinic`.
- Confirm `profiles.role = clinic_owner`.
- Confirm clinic row is created with `status = draft`.
- Confirm `clinic_members.role = clinic_owner`.
- Confirm `clinic_members.status = active`.
- Confirm clinic owner reaches `/dashboard`.

## Login And Logout

- Log in with valid email/password.
- See dashboard or mobile home based on role.
- Log out.
- Confirm protected pages require login again.

## Protected Admin Routes

- Open `/dashboard` while logged out.
- Confirm redirect to `/login`.
- Log in as `pet_owner`.
- Confirm admin access is blocked.
- Log in as `clinic_owner`.
- Confirm dashboard is visible.

## RLS

- Try to read another owner's pet.
- Try to read another clinic's appointment.
- Try to read draft visit records as pet owner.
- Try to read private visit document metadata from unrelated account.
- Confirm all are denied.

