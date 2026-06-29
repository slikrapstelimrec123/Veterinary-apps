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
      <StatCard label="Clinic" value={clinic?.name ?? "No clinic"} note={`Status: ${clinic?.status ?? "unknown"}`} />
      <StatCard label="Doctors" value={String(activeDoctors)} note={`${doctors.length} total visible in workspace`} />
      <StatCard label="Services" value={String(activeServices)} note={`${services.length} total configured`} />
      <StatCard label="Profile" value={`${completionPercent}%`} note="Completion before publishing" />
    </section>
  );
}

