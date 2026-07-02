# Pivot Testing Checklist

## Mobile

- Open the app in mock mode.
- Confirm bottom navigation shows: Home, Pets, Reminders, Documents, QR/PDF, Settings.
- Add or edit a pet and fill passport fields.
- Open pet profile and verify allergies, chronic conditions, contacts, and microchip are visible.
- Open Preventive Care from pet profile.
- Open Reminders and mark one reminder completed.
- Open Documents and verify owner-managed document cards.
- Open QR/PDF and verify the public card and PDF summary placeholder.
- Confirm clinic search is only accessible from the pilot card on Home.

## Web

- Open `/` and verify the landing page says "Цифровий паспорт тварини".
- Submit waitlist form with consent.
- Confirm validation appears when email or consent is missing.
- Open `/login` for clinic cabinet access.

## Security

- Confirm new Supabase tables have RLS enabled.
- Confirm owner policies use `owner_id = auth.uid()` and `public.owns_pet(pet_id)`.
- Confirm public QR reads only enabled `pet_public_profiles`.
- Confirm waitlist insert requires consent.
