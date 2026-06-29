# Veterinary Care Platform PRD

## 1. Product Summary

### What The App Is

A premium, minimalistic veterinary healthcare platform that connects pet owners with veterinary clinics and keeps each pet's medical history in one trusted place.

The product has two main surfaces:

- **Mobile app for pet owners**: Flutter app for iOS and Android.
- **Web admin panel for clinics**: Next.js dashboard for clinic teams.

The platform is not just a clinic catalog. The core product object is the **pet medical card**, where appointments, diagnoses, treatment notes, documents, photos, certificates, and recommendations are stored.

### Who It Is For

- **Pet owners** who need a simple way to manage pets, appointments, medical history, documents, and reminders.
- **Veterinary clinics** that need a modern digital cabinet for profiles, doctors, services, schedules, bookings, clients, pets, and visit records.
- **Veterinarians** who need fast access to patient history and a structured way to add visit results.
- **Clinic receptionists/managers** who manage appointments, clients, doctors, and day-to-day clinic operations.
- **Platform administrators** who moderate clinics, support users, and manage platform settings.

### Main Value Proposition

Pet owners always have the full medical history of their pets in one place, while veterinary clinics get a simple digital workspace for appointments, clients, doctors, services, and medical records.

### Why Clinics Would Use It

- Manage bookings without messy chats, calls, and spreadsheets.
- Keep client and pet records organized.
- Add visit notes, diagnoses, documents, and photos in one place.
- Improve client experience with a polished modern service.
- Prepare for future subscriptions, analytics, CRM, reminders, and online payments.

### Why Pet Owners Would Use It

- Keep all pet health data in one app.
- Book appointments without calling.
- See clinic, doctor, service, date, time, and price before confirming.
- Access visit history, diagnoses, documents, and recommendations after appointments.
- Manage multiple pets from one account.

## 2. User Roles And Permissions

### Pet Owner

Primary user of the mobile app.

Permissions:

- Create and manage own profile.
- Create and manage own pet profiles.
- Link co-owners to a pet later, outside MVP.
- Search published clinics, doctors, and services.
- Book, view, cancel, or reschedule own appointments, subject to clinic rules.
- View visit records, documents, photos, recommendations, and certificates for pets they own.
- Upload owner-side pet photos or documents if enabled later.
- Leave clinic or doctor reviews after completed appointments.

Restrictions:

- Cannot view pets they do not own.
- Cannot edit clinic-created medical records.
- Cannot access clinic internal notes.
- Cannot access unpublished clinic data.

### Clinic Owner / Admin

Main business owner of a clinic workspace.

Permissions:

- Register a clinic.
- Edit clinic profile, contacts, address, photos, working hours, and publication status.
- Add, edit, deactivate doctors.
- Add and edit services and prices.
- Manage doctor schedules.
- View and manage clinic appointments.
- View clinic clients and pets connected to clinic appointments or visits.
- Create and edit visit records for clinic appointments.
- Upload documents, photos, certificates, diagnoses, and recommendations.
- Invite clinic members.
- Manage member roles.
- View subscription status.

Restrictions:

- Cannot access data from other clinics.
- Cannot access pet records that have no relationship with the clinic.
- Cannot override platform moderation or billing state.

### Veterinarian

Medical role inside a clinic workspace.

Permissions:

- View own profile and assigned clinic profile.
- View own schedule.
- View appointments assigned to them.
- View pet card and previous records available to the clinic.
- Create visit records for appointments in their clinic.
- Add diagnosis, treatment notes, recommendations, internal notes, and document attachments.
- Update visit status.

Restrictions:

- Cannot manage clinic billing.
- Cannot manage all clinic members unless also given admin permissions.
- Cannot create records for other clinics.
- Cannot view appointments outside assigned clinic access.

### Clinic Receptionist / Manager

Operational role inside a clinic workspace.

Permissions:

- View and manage appointment calendar.
- Create appointments manually for phone or walk-in clients.
- View client and pet profiles connected to the clinic.
- Manage service booking details.
- Upload non-medical documents if permitted by clinic settings.
- Help update schedules and availability if allowed by admin.

Restrictions:

- Cannot edit final medical diagnosis unless granted medical permissions.
- Cannot manage billing or clinic ownership.
- Cannot access other clinics.

### Platform Admin

Internal operator of the entire platform.

Permissions:

- View platform-level users, clinics, subscriptions, and moderation queue.
- Approve, reject, suspend, or unpublish clinics.
- Support clinics and pet owners.
- Manage platform taxonomy, support content, and system settings.
- Investigate security or abuse cases with audited access.

Restrictions:

- Medical data access should be limited, audited, and only used for support, compliance, or security.
- Platform admin actions must be logged.

## 3. MVP Scope

The first version should test the idea with **5-10 veterinary clinics**. It should be small enough to build quickly, but complete enough to prove whether clinics and pet owners will actually use the workflow.

### MVP Includes

Pet owner mobile app:

- Account registration and login.
- Owner profile.
- Create and manage pet profiles.
- List own pets.
- Pet card with basic health information.
- Browse/search published clinics.
- View clinic profile.
- View clinic services.
- View doctors in a clinic.
- Book an appointment with pet, clinic, service, doctor/date/time.
- View own appointments.
- View pet treatment history created by clinics.
- View uploaded documents/photos from clinic visits.

Clinic web admin:

- Clinic registration and profile setup.
- Clinic publication status: draft/published.
- Add and edit doctors.
- Add and edit services and prices.
- Set simple doctor schedule.
- View appointment list/calendar.
- Change appointment status.
- View client and pet records connected to clinic appointments.
- Create visit records after appointment.
- Upload visit documents and photos.

Backend:

- Supabase Auth.
- PostgreSQL database with Row Level Security.
- Private Supabase Storage buckets for medical documents.
- Public read access only for published clinic, doctor, and service profiles.
- Role-based clinic access via `clinic_members`.

### MVP Does Not Include

- Marketplace promotion logic.
- Complex doctor discovery across all clinics.
- Online payments.
- Subscriptions enforcement.
- Insurance workflows.
- Video consultations.
- Chat.
- AI diagnosis or recommendation generation.
- Inventory management.
- Advanced analytics.
- Multi-branch enterprise clinic chains.
- Loyalty programs.

## 4. Features Outside MVP

Build later after real clinic testing:

- Clinic paid plans and billing automation.
- Online appointment prepayment.
- Apple/Google subscriptions for pet owner premium.
- Push reminders for vaccines, visits, medications, and documents.
- Clinic CRM campaigns.
- Chat between owner and clinic.
- Telemedicine or video consultation.
- Advanced doctor search by specialty, rating, distance, language, and availability.
- Multi-location clinic network support.
- Inventory and pharmacy.
- Lab integrations.
- Insurance integrations.
- Referral program.
- Clinic analytics dashboard.
- Platform moderation console.
- Owner-side document uploads.
- Co-owners and family access to pets.
- Emergency clinic availability.
- Offline mode for clinic staff.

## 5. MVP Success Criteria

The MVP is successful if:

- 5-10 clinics can register and configure profiles without direct developer help.
- Clinic staff can add doctors, services, schedules, and appointments.
- Pet owners can create pets and book appointments without confusion.
- Clinics can create visit records and upload documents.
- Pet owners return to view treatment history after visits.
- RLS prevents cross-clinic and cross-owner data leaks.
- Clinic staff can use the admin panel with minimal training.

## 6. Product Principles

- The pet card is the center of the product.
- Keep every screen calm, clear, and medically trustworthy.
- Use short forms and progressive steps.
- Make primary actions visible.
- Avoid overloaded dashboards.
- Treat medical records and uploaded files as sensitive private data.
- Do not build marketplace complexity until clinics and owners prove the core loop.

