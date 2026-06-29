# Mobile Pet Owner Test Checklist

Use this after applying migrations and running the Flutter app.

## Preview Mode

- Run `flutter run -d chrome --dart-define=MOCK_MODE=true`.
- Confirm app opens without Supabase env values.
- Confirm mock home shows pet count and pet previews.
- Confirm mock visit history contains example records.

## Access

- Pet owner can open mobile home screen.
- Clinic owner, clinic manager, and veterinarian see the web admin panel message.
- Platform admin sees restricted mobile access message.
- Logout returns to login screen.

## Pets

- Pet owner can view pet list.
- Empty pet list shows: `No pets yet. Add your first pet to keep their medical history in one place.`
- Pet owner can create a pet.
- Pet owner can edit their own pet.
- Name is required.
- Species is required.
- Weight must be positive when provided.
- Birth date cannot be in the future.
- Pet owner cannot access another user's pet through RLS.

## Pet Profile

- Pet profile shows avatar placeholder, name, species, breed, sex, age, weight, microchip, and notes.
- Treatment history button opens records for selected pet.
- Book appointment shows next-stage placeholder.
- Documents opens metadata placeholder/list.

## Treatment History

- Pet owner can view records for their own pet.
- Empty history shows: `No treatment records yet. Records will appear here after a clinic adds them.`
- Visit detail shows visit date, clinic, doctor, reason, diagnosis, treatment, recommendations, next visit, and document metadata.
- Document action does not expose public file URLs.

