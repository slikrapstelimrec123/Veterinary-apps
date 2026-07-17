# Architecture

## Mobile

`apps/mobile` is a feature-oriented Flutter application:

- `core` — authentication, configuration, navigation, theme, local notifications;
- `features` — pets, owner visit records, documents, medications, feeding, events, notifications, announcements, transfers, and settings;
- `shared` — reusable widgets, storage helpers, and mock data.

The mobile app is the only product surface. There is no clinic web application or online booking module.

## Backend

Supabase provides:

- Auth with email/password, Google, and Apple;
- PostgreSQL with RLS;
- private Storage for pet and medical files;
- narrow RPCs for operations that need atomic backend checks.

The latest migrations support owner-created medical records and revoke app-role access to retained legacy clinic tables.

## Data Access

- UI reads through feature repositories.
- Every owner table is protected by `auth.uid()` and pet ownership checks.
- Sensitive files use storage paths derived from the authenticated user and pet.
- The mobile app never contains `service_role` credentials.

## Product Boundary

Medical records are self-reported by owners. `provider_name` is optional reference text only; it does not create a doctor or clinic relationship.
