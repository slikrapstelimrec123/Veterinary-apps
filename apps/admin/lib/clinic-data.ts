import { createSupabaseServerClient } from "./supabase-server";
import { requireClinicAccess } from "./auth";
import type { Appointment, Clinic, Doctor, DoctorSchedule, Service, VisitRecord } from "../types";

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

export function canManageClinicAppointments(role: string) {
  return role === "clinic_owner" || role === "clinic_manager";
}

export async function getClinicAppointmentsData() {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();

  const [appointmentsResult, doctorsResult] = await Promise.all([
    supabase
      .from("appointments")
      .select("*, pets(id,name,species,breed), profiles!appointments_owner_id_fkey(id,full_name,email,phone), doctors(id,profile_id,full_name,specialization), services(id,name,duration_minutes)")
      .eq("clinic_id", context.clinicId)
      .order("appointment_date", { ascending: true })
      .order("start_time", { ascending: true }),
    supabase.from("doctors").select("id,clinic_id,full_name,specialization,status,is_public").eq("clinic_id", context.clinicId).neq("status", "archived").order("full_name", { ascending: true }),
  ]);

  const appointments = ((appointmentsResult.data ?? []) as Appointment[]).filter((appointment) => {
    if (context.clinicRole !== "veterinarian") {
      return true;
    }

    return appointment.doctors?.profile_id === context.profile.id;
  });

  return {
    context,
    appointments,
    doctors: (doctorsResult.data ?? []) as Doctor[],
  };
}

export async function getClinicAppointmentDetails(id: string) {
  const { context, appointments, doctors } = await getClinicAppointmentsData();
  const appointment = appointments.find((item) => item.id === id) ?? null;
  const supabase = createSupabaseServerClient();
  const { data: visitRecord } = appointment
    ? await supabase.from("visit_records").select("id,status").eq("appointment_id", appointment.id).eq("clinic_id", context.clinicId).maybeSingle()
    : { data: null };

  return {
    context,
    appointment,
    doctors,
    visitRecord: visitRecord as Pick<VisitRecord, "id" | "status"> | null,
  };
}

export async function getClinicVisitRecordsData() {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();

  const { data } = await supabase
    .from("visit_records")
    .select("*, pets(id,name,species,breed), profiles!visit_records_owner_id_fkey(id,full_name,email,phone), doctors(id,profile_id,full_name,specialization), visit_documents(id,is_visible_to_owner)")
    .eq("clinic_id", context.clinicId)
    .order("visit_date", { ascending: false });

  const records = ((data ?? []) as VisitRecord[]).filter((record) => {
    if (context.clinicRole !== "veterinarian") {
      return true;
    }

    return record.created_by === context.profile.id || record.doctors?.profile_id === context.profile.id;
  });

  return { context, records };
}

export async function getClinicVisitRecordDetails(id: string) {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();

  const { data } = await supabase
    .from("visit_records")
    .select("*, pets(id,name,species,breed), profiles!visit_records_owner_id_fkey(id,full_name,email,phone), doctors(id,profile_id,full_name,specialization), appointments(*, services(id,name,duration_minutes)), visit_documents(*)")
    .eq("id", id)
    .eq("clinic_id", context.clinicId)
    .maybeSingle();

  const record = data as VisitRecord | null;

  if (record && context.clinicRole === "veterinarian" && record.created_by !== context.profile.id && record.doctors?.profile_id !== context.profile.id) {
    return { context, record: null };
  }

  return { context, record };
}

export async function getVisitRecordCreateData(appointmentId: string) {
  const { context, appointment, doctors, visitRecord } = await getClinicAppointmentDetails(appointmentId);

  return {
    context,
    appointment,
    doctors,
    existingRecord: visitRecord,
  };
}

export function profileCompletion(clinic: Clinic | null, services: Service[], doctors: Doctor[], schedules: DoctorSchedule[]) {
  const items = [
    { label: "Додати логотип клініки", done: Boolean(clinic?.logo_url) },
    { label: "Додати адресу клініки", done: Boolean(clinic?.city && clinic?.address) },
    { label: "Додати хоча б одну послугу", done: services.some((service) => service.status === "active") },
    { label: "Додати хоча б одного лікаря", done: doctors.some((doctor) => doctor.status === "active") },
    { label: "Додати розклад лікаря", done: schedules.some((schedule) => schedule.is_active) },
  ];

  const completed = items.filter((item) => item.done).length;

  return {
    items,
    completed,
    total: items.length,
    percent: Math.round((completed / items.length) * 100),
  };
}
