"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase-server";
import { requireClinicAccess } from "./auth";
import { canManageClinicCatalog, canManageClinicProfile } from "./clinic-data";

function text(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function numberOrNull(formData: FormData, key: string) {
  const value = text(formData, key);
  if (!value) {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function checked(formData: FormData, key: string) {
  return formData.get(key) === "on";
}

function assertCatalogPermission(role: string) {
  if (!canManageClinicCatalog(role)) {
    redirect("/dashboard?error=permission");
  }
}

function assertProfilePermission(role: string) {
  if (!canManageClinicProfile(role)) {
    redirect("/dashboard?error=permission");
  }
}

function revalidateClinicPages() {
  revalidatePath("/dashboard");
  revalidatePath("/clinic/profile");
  revalidatePath("/clinic/services");
  revalidatePath("/clinic/doctors");
  revalidatePath("/clinic/schedule");
}

export async function updateClinicProfile(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertProfilePermission(clinicRole);

  const name = text(formData, "name");
  const city = text(formData, "city");
  const address = text(formData, "address");
  const phone = text(formData, "phone");
  const email = text(formData, "email");
  const requestedStatus = text(formData, "status") ?? "draft";
  const status = ["draft", "pending_verification", "published"].includes(requestedStatus) ? requestedStatus : "draft";
  const published = checked(formData, "published");

  if (!name || !city || (published && (!address || (!phone && !email)))) {
    redirect("/clinic/profile?error=publish_requirements");
  }

  const nextStatus = published ? "published" : status === "published" ? "draft" : status;
  const supabase = createSupabaseServerClient();
  const { error } = await supabase
    .from("clinics")
    .update({
      name,
      description: text(formData, "description"),
      phone,
      email,
      website: text(formData, "website"),
      city,
      country: text(formData, "country"),
      address,
      logo_url: text(formData, "logo_url"),
      cover_image_url: text(formData, "cover_image_url"),
      status: nextStatus,
      published,
    })
    .eq("id", clinicId);

  if (error) {
    redirect("/clinic/profile?error=unknown");
  }

  revalidateClinicPages();
  redirect("/clinic/profile?success=saved");
}

export async function createService(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const name = text(formData, "name");
  const duration = numberOrNull(formData, "duration_minutes");
  const price = numberOrNull(formData, "price_amount");

  if (!name || (duration !== null && duration <= 0) || (price !== null && price < 0)) {
    redirect("/clinic/services?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { error } = await supabase.from("services").insert({
    clinic_id: clinicId,
    name,
    description: text(formData, "description"),
    category: text(formData, "category"),
    duration_minutes: duration,
    price_amount: price,
    status: text(formData, "status") ?? "inactive",
    is_public: checked(formData, "is_public"),
  });

  if (error) {
    redirect("/clinic/services?error=unknown");
  }

  revalidateClinicPages();
  redirect("/clinic/services?success=created");
}

export async function updateService(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const id = text(formData, "id");
  const name = text(formData, "name");
  const duration = numberOrNull(formData, "duration_minutes");
  const price = numberOrNull(formData, "price_amount");

  if (!id || !name || (duration !== null && duration <= 0) || (price !== null && price < 0)) {
    redirect("/clinic/services?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { error } = await supabase
    .from("services")
    .update({
      name,
      description: text(formData, "description"),
      category: text(formData, "category"),
      duration_minutes: duration,
      price_amount: price,
      status: text(formData, "status") ?? "inactive",
      is_public: checked(formData, "is_public"),
    })
    .eq("id", id)
    .eq("clinic_id", clinicId);

  if (error) {
    redirect("/clinic/services?error=unknown");
  }

  revalidateClinicPages();
  redirect("/clinic/services?success=saved");
}

export async function deactivateService(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/services?error=not_found");
  }

  await createSupabaseServerClient().from("services").update({ status: "inactive" }).eq("id", id).eq("clinic_id", clinicId);
  revalidateClinicPages();
  redirect("/clinic/services?success=deactivated");
}

export async function deleteService(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/services?error=not_found");
  }

  const supabase = createSupabaseServerClient();
  const { count } = await supabase
    .from("appointments")
    .select("id", { count: "exact", head: true })
    .eq("service_id", id);

  if (count && count > 0) {
    await supabase.from("services").update({ status: "archived" }).eq("id", id).eq("clinic_id", clinicId);
    revalidateClinicPages();
    redirect("/clinic/services?error=unsafe_delete");
  }

  await supabase.from("services").delete().eq("id", id).eq("clinic_id", clinicId);
  revalidateClinicPages();
  redirect("/clinic/services?success=deleted");
}

export async function createDoctor(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const fullName = text(formData, "full_name");
  const specialization = text(formData, "specialization");
  const experience = numberOrNull(formData, "experience_years");
  const email = text(formData, "email");

  if (!fullName || !specialization || (experience !== null && experience < 0) || (email && !email.includes("@"))) {
    redirect("/clinic/doctors?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data, error } = await supabase
    .from("doctors")
    .insert({
      clinic_id: clinicId,
      full_name: fullName,
      specialization,
      bio: text(formData, "bio"),
      experience_years: experience,
      avatar_url: text(formData, "avatar_url"),
      phone: text(formData, "phone"),
      email,
      status: text(formData, "status") ?? "draft",
      is_public: checked(formData, "is_public"),
    })
    .select("id")
    .single();

  if (error || !data) {
    redirect("/clinic/doctors?error=unknown");
  }

  revalidateClinicPages();
  redirect(`/clinic/doctors/${data.id}?success=created`);
}

export async function updateDoctor(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const id = text(formData, "id");
  const fullName = text(formData, "full_name");
  const specialization = text(formData, "specialization");
  const experience = numberOrNull(formData, "experience_years");
  const email = text(formData, "email");

  if (!id || !fullName || !specialization || (experience !== null && experience < 0) || (email && !email.includes("@"))) {
    redirect(id ? `/clinic/doctors/${id}?error=validation` : "/clinic/doctors?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { error } = await supabase
    .from("doctors")
    .update({
      full_name: fullName,
      specialization,
      bio: text(formData, "bio"),
      experience_years: experience,
      avatar_url: text(formData, "avatar_url"),
      phone: text(formData, "phone"),
      email,
      status: text(formData, "status") ?? "draft",
      is_public: checked(formData, "is_public"),
    })
    .eq("id", id)
    .eq("clinic_id", clinicId);

  if (error) {
    redirect(`/clinic/doctors/${id}?error=unknown`);
  }

  revalidateClinicPages();
  redirect(`/clinic/doctors/${id}?success=saved`);
}

export async function deactivateDoctor(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/doctors?error=not_found");
  }

  await createSupabaseServerClient().from("doctors").update({ status: "inactive" }).eq("id", id).eq("clinic_id", clinicId);
  revalidateClinicPages();
  redirect("/clinic/doctors?success=deactivated");
}

export async function deleteDoctor(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/doctors?error=not_found");
  }

  const supabase = createSupabaseServerClient();
  const { count } = await supabase.from("appointments").select("id", { count: "exact", head: true }).eq("doctor_id", id);

  if (count && count > 0) {
    await supabase.from("doctors").update({ status: "archived" }).eq("id", id).eq("clinic_id", clinicId);
    revalidateClinicPages();
    redirect("/clinic/doctors?error=unsafe_delete");
  }

  await supabase.from("doctors").delete().eq("id", id).eq("clinic_id", clinicId);
  revalidateClinicPages();
  redirect("/clinic/doctors?success=deleted");
}

export async function createSchedule(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const doctorId = text(formData, "doctor_id");
  const dayOfWeek = numberOrNull(formData, "day_of_week");
  const startTime = text(formData, "start_time");
  const endTime = text(formData, "end_time");
  const slotDuration = numberOrNull(formData, "slot_duration_minutes") ?? 30;

  if (!doctorId || !dayOfWeek || dayOfWeek < 1 || dayOfWeek > 7 || !startTime || !endTime || startTime >= endTime || slotDuration <= 0) {
    redirect("/clinic/schedule?error=validation");
  }

  const breakStart = text(formData, "break_start_time");
  const breakEnd = text(formData, "break_end_time");

  if ((breakStart || breakEnd) && (!breakStart || !breakEnd || breakStart <= startTime || breakEnd >= endTime || breakStart >= breakEnd)) {
    redirect("/clinic/schedule?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data: doctor } = await supabase.from("doctors").select("id").eq("id", doctorId).eq("clinic_id", clinicId).maybeSingle();

  if (!doctor) {
    redirect("/clinic/schedule?error=not_found");
  }

  const { error } = await supabase.from("doctor_schedules").insert({
    clinic_id: clinicId,
    doctor_id: doctorId,
    day_of_week: dayOfWeek,
    start_time: startTime,
    end_time: endTime,
    break_start_time: breakStart,
    break_end_time: breakEnd,
    slot_duration_minutes: slotDuration,
    is_active: checked(formData, "is_active"),
  });

  if (error) {
    redirect(error.code === "23505" ? "/clinic/schedule?error=duplicate_schedule" : "/clinic/schedule?error=unknown");
  }

  revalidateClinicPages();
  redirect("/clinic/schedule?success=created");
}

export async function updateSchedule(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);

  const id = text(formData, "id");
  const startTime = text(formData, "start_time");
  const endTime = text(formData, "end_time");
  const slotDuration = numberOrNull(formData, "slot_duration_minutes") ?? 30;
  const breakStart = text(formData, "break_start_time");
  const breakEnd = text(formData, "break_end_time");

  if (!id || !startTime || !endTime || startTime >= endTime || slotDuration <= 0) {
    redirect("/clinic/schedule?error=validation");
  }

  if ((breakStart || breakEnd) && (!breakStart || !breakEnd || breakStart <= startTime || breakEnd >= endTime || breakStart >= breakEnd)) {
    redirect("/clinic/schedule?error=validation");
  }

  const { error } = await createSupabaseServerClient()
    .from("doctor_schedules")
    .update({
      start_time: startTime,
      end_time: endTime,
      break_start_time: breakStart,
      break_end_time: breakEnd,
      slot_duration_minutes: slotDuration,
      is_active: checked(formData, "is_active"),
    })
    .eq("id", id)
    .eq("clinic_id", clinicId);

  if (error) {
    redirect("/clinic/schedule?error=unknown");
  }

  revalidateClinicPages();
  redirect("/clinic/schedule?success=saved");
}

export async function deleteSchedule(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertCatalogPermission(clinicRole);
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/schedule?error=not_found");
  }

  await createSupabaseServerClient().from("doctor_schedules").delete().eq("id", id).eq("clinic_id", clinicId);
  revalidateClinicPages();
  redirect("/clinic/schedule?success=deleted");
}
