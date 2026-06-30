import { StatCard } from "./stat-card";
import type { Clinic, Doctor, Service } from "../types";

export function ClinicDashboardCards({
  clinic,
  doctors,
  services,
  completionPercent,
}: {
  clinic: Clinic | null;
  doctors: Doctor[];
  services: Service[];
  completionPercent: number;
}) {
  const activeDoctors = doctors.filter((doctor) => doctor.status === "active").length;
  const activeServices = services.filter((service) => service.status === "active").length;

  return (
    <section className="grid">
      <StatCard label="Клініка" value={clinic?.name ?? "Немає клініки"} note={`Статус: ${clinic?.status ?? "невідомо"}`} />
      <StatCard label="Лікарі" value={String(activeDoctors)} note={`${doctors.length} загалом відображаються в робочому просторі`} />
      <StatCard label="Послуги" value={String(activeServices)} note={`${services.length} загалом налаштовано`} />
      <StatCard label="Профіль" value={`${completionPercent}%`} note="Заповненість перед публікацією" />
    </section>
  );
}
