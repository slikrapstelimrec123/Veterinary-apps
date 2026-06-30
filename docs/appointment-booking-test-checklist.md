# Appointment Booking Test Checklist

## Mobile Pet Owner

- Bottom navigation shows Home, Pets, Clinics, Appointments, and Settings.
- Clinics tab shows only published clinics.
- Clinic search matches by clinic name, city, or address.
- Clinic profile shows public services and public active doctors.
- Doctor profile opens from clinic profile and can start booking with doctor preselected.
- Booking requires pet, clinic, service, doctor, date, and time.
- Slot list excludes past slots, schedule breaks, and overlapping appointments.
- Booking creates a pending appointment.
- Confirmation screen shows clinic, pet, service, doctor, date, time, and pending status.
- Appointments tab shows owner appointments.
- Owner can open appointment details.
- Owner can cancel pending or confirmed appointment.

## Clinic Admin

- Sidebar opens `/clinic/appointments`.
- Clinic owner or manager can view clinic appointments.
- Veterinarian sees only assigned appointments.
- Pending appointment can be confirmed.
- Appointment detail can change status to confirmed, completed, cancelled by clinic, or no-show.
- Appointment detail can assign or clear a doctor.
- Clinic note and cancellation reason can be saved.
- Create visit record button is disabled and clearly marked as next stage.

## Security

- Pet owner cannot book for a pet they do not own.
- Pet owner cannot create appointments in unpublished clinics.
- Pet owner cannot create appointments for inactive/private services or doctors.
- Public schedule access exposes only active public doctors in published clinics.
- Owner cancellation can only set `cancelled_by_owner`.
- Clinic appointment updates require clinic owner, clinic manager, or platform admin role.

## Out Of Scope For This Stage

- Visit record creation.
- Real document upload or file viewing.
- Payments and subscriptions.
- Reviews, ratings, marketplace ranking, chat, push notifications, telemedicine, insurance, or AI features.
