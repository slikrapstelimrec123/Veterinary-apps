# Beta QA Checklist

## Critical Flows

- Register, sign in, OAuth callback, password reset, and logout.
- Create, edit, and delete a pet.
- Pet avatar appears consistently on home, pet list, pet card, announcements, and transfers.
- Create, edit, and delete an owner medical visit.
- Upload, open, export, and delete private documents.
- Create and edit medication, feeding, and event records.
- Notification permission is requested and reminders appear with sound when enabled.
- In-app notification inbox updates without an application restart.
- Create and edit announcements, including phone number and photos.
- Transfer a pet and receive the request immediately.
- Export data and request account deletion.

## Security

- Account A cannot access account B data or files.
- Signed-out requests fail.
- Storage paths cannot be guessed to access private files.
- OAuth redirects only to approved URLs.
- No secret keys appear in source, logs, or build artifacts.
