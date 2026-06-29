import type { Appointment, Clinic, Doctor, Pet, Service, VisitRecord } from "../types";

export const clinic: Clinic = {
  id: "clinic_1",
  name: "North Star Vet Clinic",
  status: "draft",
  published: false,
  city: "Kyiv",
  country: "Ukraine",
  address: "Central Avenue 12",
};

export const doctors: Doctor[] = [
  { id: "doctor_1", clinic_id: "clinic_1", full_name: "Dr. Anna Kovalenko", specialization: "General care", status: "active", is_public: true },
  { id: "doctor_2", clinic_id: "clinic_1", full_name: "Dr. Max Levin", specialization: "Surgery", status: "draft", is_public: false },
];

export const services: Service[] = [
  { id: "service_1", clinic_id: "clinic_1", name: "Consultation", duration_minutes: 30, price_amount: 600, status: "active", is_public: true },
  { id: "service_2", clinic_id: "clinic_1", name: "Vaccination", duration_minutes: 20, price_amount: 450, status: "active", is_public: true },
];

export const pets: Pet[] = [
  { id: "pet_1", name: "Luna", species: "Dog", breed: "Corgi" },
  { id: "pet_2", name: "Milo", species: "Cat", breed: "British Shorthair" },
];

export const appointments: Appointment[] = [
  { id: "appointment_1", clinicId: "clinic_1", petId: "pet_1", ownerName: "Olena Petrenko", startsAt: "2026-07-01 10:30", status: "scheduled" },
  { id: "appointment_2", clinicId: "clinic_1", petId: "pet_2", ownerName: "Dmytro Horbunov", startsAt: "2026-07-01 12:00", status: "confirmed" },
];

export const visitRecords: VisitRecord[] = [
  { id: "visit_1", clinicId: "clinic_1", petId: "pet_1", diagnosis: "Preventive checkup", status: "completed" },
];
