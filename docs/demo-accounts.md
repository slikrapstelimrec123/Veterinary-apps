# Demo Accounts For Beta

Create these users locally through Supabase Auth or the app registration flows. Do not commit real passwords.

Recommended fake emails:

- `demo.pet.owner@example.com` - `pet_owner`
- `demo.clinic.owner@example.com` - `clinic_owner`
- `demo.vet@example.com` - `veterinarian`
- `demo.manager@example.com` - `clinic_manager`
- `demo.platform.admin@example.com` - `platform_admin`

After auth users exist, run:

```bash
supabase db reset
```

or apply migrations and then seed manually with your local database connection:

```bash
psql "$SUPABASE_DB_URL" -f supabase/seed/seed.sql
```

The seed creates fake clinic, doctors, services, schedules, pets, ownership links, appointments, visit records, document metadata, reviews, notifications, and clinic subscription state.

Never use real clinic, client, pet, or medical data for demo accounts.
