# AI Agent Instructions

This repository is an MVP for a veterinary clinics and pet owners platform.

## Product Rules

- Follow the MVP scope in `docs/prd.md`.
- Treat the pet medical card as the center of the product.
- Keep clinic workflows simple enough for non-technical staff.
- Do not add features outside the requested stage.
- Do not implement payments yet.
- Do not implement chat, push notifications, AI features, ratings marketplace, complex CRM, insurance, or telemedicine in this stage.

## Engineering Rules

- Keep code clean, readable, and maintainable.
- Prefer simple architecture over clever abstractions.
- Use TypeScript in the admin panel.
- Keep folder structure clear and feature-oriented.
- Do not hardcode secrets or environment-specific values.
- Add comments only where they clarify non-obvious logic.
- Use placeholder data only until backend integration is requested.
- Keep Supabase Row Level Security as the source of truth for sensitive access control.

## Security And Privacy

- Pet records, visit records, and uploaded documents are sensitive medical data.
- Pet owners must see only their own pets and treatment history.
- Clinics must see only data connected to their clinic.
- Doctors must create visit records only for appointments in their clinic.
- Uploaded documents must remain private.
- Public users can view only published clinic, doctor, and service profiles.

## UI Rules

- Keep UI minimalistic, premium, calm, medical, and trustworthy.
- Avoid overloaded screens.
- Use clear hierarchy, readable typography, and restrained colors.
- Make primary actions obvious.
- Protect destructive or high-impact actions with confirmation.

