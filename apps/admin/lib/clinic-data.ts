import { createSupabaseServerClient } from "./supabase-server";
import { requireClinicAccess } from "./auth";
import type { Clinic, Doctor, DoctorSchedule, Service } from "../types";

export type ClinicContext = Awaited<ReturnType<typeof requireClinicAccess>>;

export async function getClinicManagementData() {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();

  const [clinicResult, doctorsResult, servicesResult, schedulesResult] = await Promise.all([
    supabase.from("clinics").select("*").eq("id", context.clinicId).maybeSingle(),
    supabase.from("doctors").select("*").eq("clinic_id", context.clinicId).neq("status", "archived").order("created_at", { ascending: false }),
    supabase.from("services").select("*").eq("clinic_id", context.clinicId).neq("status", "archived").order("created_at", { ascending: false }),
    supabase
      .from("doctor_schedules")
      .select("*, doctors(id, full_name, specialization)")
      .eq("clinic_id", context.clinicId)
      .order("day_of_week", { ascending: true }),
  ]);

  return {
    context,
    clinic: clinicResult.data as Clinic | null,
    doctors: (doctorsResult.data ?? []) as Doctor[],
    services: (servicesResult.data ?? []) as Service[],
    schedules: (schedulesResult.data ?? []) as DoctorSchedule[],
  };
}

export function canManageClinicCatalog(role: string) {
  return role === "clinic_owner" || role === "clinic_manager";
}

export function canManageClinicProfile(role: string) {
  return role === "clinic_owner" || role === "clinic_manager";
}

export function profileCompletion(clinic: Clinic | null, services: Service[], doctors: Doctor[], schedules: DoctorSchedule[]) {
  const items = [
    { label: "Add clinic logo", done: Boolean(clinic?.logo_url) },
    { label: "Add clinic address", done: Boolean(clinic?.city && clinic?.address) },
    { label: "Add at least one service", done: services.some((service) => service.status === "active") },
    { label: "Add at least one doctor", done: doctors.some((doctor) => doctor.status === "active") },
    { label: "Add doctor schedule", done: schedules.some((schedule) => schedule.is_active) },
  ];

  const completed = items.filter((item) => item.done).length;

  return {
    items,
    completed,
    total: items.length,
    percent: Math.round((completed / items.length) * 100),
  };
}

