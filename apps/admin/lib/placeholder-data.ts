import type { Appointment, Clinic, Doctor, Pet, Service, VisitRecord } from "../types";

export const clinic: Clinic = {
  id: "clinic_1",
  name: "Ветклініка Північна Зірка",
  status: "draft",
  published: false,
  city: "Київ",
  country: "Україна",
  address: "Центральний проспект, 12",
};

export const doctors: Doctor[] = [
  { id: "doctor_1", clinic_id: "clinic_1", full_name: "Лікар Анна Коваленко", specialization: "Загальна терапія", status: "active", is_public: true },
  { id: "doctor_2", clinic_id: "clinic_1", full_name: "Лікар Максим Левін", specialization: "Хірургія", status: "draft", is_public: false },
];

export const services: Service[] = [
  { id: "service_1", clinic_id: "clinic_1", name: "Консультація", duration_minutes: 30, price_amount: 600, status: "active", is_public: true },
  { id: "service_2", clinic_id: "clinic_1", name: "Вакцинація", duration_minutes: 20, price_amount: 450, status: "active", is_public: true },
];

export const pets: Pet[] = [
  { id: "pet_1", name: "Luna", species: "Собака", breed: "Коргі" },
  { id: "pet_2", name: "Milo", species: "Кіт", breed: "Британська короткошерста" },
];

export const appointments: Appointment[] = [
  { id: "appointment_1", clinicId: "clinic_1", petId: "pet_1", ownerName: "Олена Петренко", startsAt: "2026-07-01 10:30", status: "scheduled" },
  { id: "appointment_2", clinicId: "clinic_1", petId: "pet_2", ownerName: "Дмитро Горбунов", startsAt: "2026-07-01 12:00", status: "confirmed" },
];

export const visitRecords: VisitRecord[] = [
  { id: "visit_1", clinicId: "clinic_1", petId: "pet_1", diagnosis: "Профілактичний огляд", status: "completed" },
];
