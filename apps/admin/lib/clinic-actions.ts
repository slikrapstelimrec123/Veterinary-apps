"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase-server";
import { getCurrentProfile, requireClinicAccess } from "./auth";
import { canManageClinicAppointments, canManageClinicCatalog, canManageClinicProfile } from "./clinic-data";
import { requirePlanCapacity } from "./subscription-data";

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

function dateText(formData: FormData, key: string) {
  const value = text(formData, key);
  return value && /^\d{4}-\d{2}-\d{2}$/.test(value) ? value : null;
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
  revalidatePath("/clinic/appointments");
  revalidatePath("/clinic/visit-records");
  revalidatePath("/clinic/reviews");
}

function assertAppointmentPermission(role: string) {
  if (!canManageClinicAppointments(role)) {
    redirect("/clinic/appointments?error=permission");
  }
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

  if (published) {
    const { data: canPublish } = await supabase.rpc("can_clinic_publish_profile", { target_clinic_id: clinicId });
    if (canPublish !== true) {
      redirect("/clinic/subscription?error=feature_locked");
    }
  }

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

  await requirePlanCapacity(clinicId, "service");

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

  await requirePlanCapacity(clinicId, "doctor");

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

export async function updateAppointmentStatus(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertAppointmentPermission(clinicRole);

  const id = text(formData, "id");
  const status = text(formData, "status");
  const returnTo = text(formData, "return_to") ?? "/clinic/appointments";

  if (!id || !status || !["pending", "confirmed", "completed", "cancelled_by_clinic", "no_show"].includes(status)) {
    redirect(`${returnTo}?error=validation`);
  }

  if (status === "confirmed") {
    await requirePlanCapacity(clinicId, "appointment");
  }

  const { error } = await createSupabaseServerClient()
    .from("appointments")
    .update({
      status,
      clinic_note: text(formData, "clinic_note"),
      cancellation_reason: status === "cancelled_by_clinic" ? text(formData, "cancellation_reason") : null,
    })
    .eq("id", id)
    .eq("clinic_id", clinicId);

  if (error) {
    redirect(`${returnTo}?error=unknown`);
  }

  revalidateClinicPages();
  revalidatePath(`/clinic/appointments/${id}`);
  redirect(`${returnTo}?success=saved`);
}

export async function assignAppointmentDoctor(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  assertAppointmentPermission(clinicRole);

  const id = text(formData, "id");
  const doctorId = text(formData, "doctor_id");
  const returnTo = text(formData, "return_to") ?? "/clinic/appointments";

  if (!id) {
    redirect(`${returnTo}?error=validation`);
  }

  if (doctorId) {
    const { data: doctor } = await createSupabaseServerClient().from("doctors").select("id").eq("id", doctorId).eq("clinic_id", clinicId).maybeSingle();
    if (!doctor) {
      redirect(`${returnTo}?error=not_found`);
    }
  }

  const { error } = await createSupabaseServerClient().from("appointments").update({ doctor_id: doctorId }).eq("id", id).eq("clinic_id", clinicId);

  if (error) {
    redirect(`${returnTo}?error=unknown`);
  }

  revalidateClinicPages();
  revalidatePath(`/clinic/appointments/${id}`);
  redirect(`${returnTo}?success=saved`);
}

function visitRecordPayload(formData: FormData, status: "draft" | "published") {
  const visitDate = dateText(formData, "visit_date");
  const nextVisitRecommended = checked(formData, "next_visit_recommended");
  const nextVisitDate = dateText(formData, "next_visit_date");
  const diagnosis = text(formData, "diagnosis");
  const treatmentNotes = text(formData, "treatment_notes");
  const recommendations = text(formData, "recommendations");

  if (!visitDate) {
    return { error: "validation" as const };
  }

  if (status === "published" && !diagnosis && !treatmentNotes && !recommendations) {
    return { error: "visit_publish_requirements" as const };
  }

  if (nextVisitRecommended && !nextVisitDate) {
    return { error: "validation" as const };
  }

  if (nextVisitRecommended && nextVisitDate && nextVisitDate < new Date().toISOString().slice(0, 10)) {
    return { error: "validation" as const };
  }

  return {
    data: {
      visit_date: visitDate,
      reason_for_visit: text(formData, "reason_for_visit"),
      reason: text(formData, "reason_for_visit"),
      symptoms: text(formData, "symptoms"),
      diagnosis,
      procedures_performed: text(formData, "procedures_performed"),
      treatment_notes: treatmentNotes,
      prescribed_medications: text(formData, "prescribed_medications"),
      recommendations,
      next_visit_recommended: nextVisitRecommended,
      next_visit_date: nextVisitRecommended ? nextVisitDate : null,
      follow_up_at: nextVisitRecommended ? nextVisitDate : null,
      internal_notes: text(formData, "internal_notes"),
      status,
    },
  };
}

export async function createVisitRecord(formData: FormData) {
  const { clinicId, clinicRole, profile } = await requireClinicAccess();
  if (!["clinic_owner", "clinic_manager", "veterinarian"].includes(clinicRole)) {
    redirect("/clinic/visit-records?error=permission");
  }

  const appointmentId = text(formData, "appointment_id");
  const action = text(formData, "submit_action");
  const status = action === "publish" ? "published" : "draft";
  const payload = visitRecordPayload(formData, status);

  if ("error" in payload) {
    redirect(appointmentId ? `/clinic/appointments/${appointmentId}/visit-record/create?error=${payload.error}` : `/clinic/visit-records?error=${payload.error}`);
  }

  const supabase = createSupabaseServerClient();
  const { data: appointment } = appointmentId
    ? await supabase
        .from("appointments")
        .select("id,clinic_id,pet_id,owner_id,doctor_id,status")
        .eq("id", appointmentId)
        .eq("clinic_id", clinicId)
        .maybeSingle()
    : { data: null };

  if (!appointment) {
    redirect("/clinic/appointments?error=not_found");
  }

  if (clinicRole === "veterinarian" && appointment.doctor_id) {
    const { data: doctor } = await supabase.from("doctors").select("profile_id").eq("id", appointment.doctor_id).eq("clinic_id", clinicId).maybeSingle();
    if (doctor?.profile_id !== profile.id) {
      redirect(`/clinic/appointments/${appointmentId}?error=permission`);
    }
  }

  await requirePlanCapacity(clinicId, "visit_record");

  const { data, error } = await supabase
    .from("visit_records")
    .insert({
      ...payload.data,
      appointment_id: appointment.id,
      clinic_id: clinicId,
      pet_id: appointment.pet_id,
      owner_id: appointment.owner_id,
      doctor_id: text(formData, "doctor_id") ?? appointment.doctor_id,
      created_by: profile.id,
    })
    .select("id")
    .single();

  if (error || !data) {
    redirect(`/clinic/appointments/${appointmentId}/visit-record/create?error=unknown`);
  }

  if (status === "published") {
    await supabase.from("appointments").update({ status: "completed" }).eq("id", appointment.id).eq("clinic_id", clinicId);
  }

  revalidateClinicPages();
  revalidatePath(`/clinic/appointments/${appointmentId}`);
  redirect(`/clinic/visit-records/${data.id}?success=created`);
}

export async function updateVisitRecord(formData: FormData) {
  const { clinicId, clinicRole } = await requireClinicAccess();
  if (!["clinic_owner", "clinic_manager", "veterinarian"].includes(clinicRole)) {
    redirect("/clinic/visit-records?error=permission");
  }

  const id = text(formData, "id");
  const action = text(formData, "submit_action");
  const status = action === "publish" ? "published" : action === "archive" ? "archived" : "draft";

  if (!id) {
    redirect("/clinic/visit-records?error=validation");
  }

  const payload = status === "archived" ? { data: { status } } : visitRecordPayload(formData, status);
  if ("error" in payload) {
    redirect(`/clinic/visit-records/${id}/edit?error=${payload.error}`);
  }

  const { error } = await createSupabaseServerClient().from("visit_records").update(payload.data).eq("id", id).eq("clinic_id", clinicId);

  if (error) {
    redirect(`/clinic/visit-records/${id}/edit?error=unknown`);
  }

  revalidateClinicPages();
  revalidatePath(`/clinic/visit-records/${id}`);
  redirect(`/clinic/visit-records/${id}?success=saved`);
}

export async function uploadVisitDocument(formData: FormData) {
  const { clinicId, profile } = await requireClinicAccess();
  const visitRecordId = text(formData, "visit_record_id");
  const fileValue = formData.get("file");
  const documentType = text(formData, "document_type") ?? "other";

  if (!visitRecordId || !(fileValue instanceof File) || fileValue.size === 0) {
    redirect(visitRecordId ? `/clinic/visit-records/${visitRecordId}?error=validation` : "/clinic/visit-records?error=validation");
  }

  if (fileValue.size > 10 * 1024 * 1024) {
    redirect(`/clinic/visit-records/${visitRecordId}?error=validation`);
  }

  const allowedTypes = ["application/pdf", "image/jpeg", "image/png", "image/heic"];
  if (!allowedTypes.includes(fileValue.type)) {
    redirect(`/clinic/visit-records/${visitRecordId}?error=validation`);
  }

  const supabase = createSupabaseServerClient();
  const { data: record } = await supabase.from("visit_records").select("id,clinic_id,pet_id").eq("id", visitRecordId).eq("clinic_id", clinicId).maybeSingle();

  if (!record) {
    redirect("/clinic/visit-records?error=not_found");
  }

  await requirePlanCapacity(clinicId, "document", fileValue.size);

  const safeName = fileValue.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const storagePath = `${clinicId}/${record.pet_id}/${visitRecordId}/${Date.now()}_${safeName}`;
  const { error: uploadError } = await supabase.storage.from("visit-documents").upload(storagePath, fileValue, {
    contentType: fileValue.type,
    upsert: false,
  });

  if (uploadError) {
    redirect(`/clinic/visit-records/${visitRecordId}?error=unknown`);
  }

  const { error } = await supabase.from("visit_documents").insert({
    visit_record_id: visitRecordId,
    clinic_id: clinicId,
    pet_id: record.pet_id,
    uploaded_by: profile.id,
    file_name: fileValue.name,
    file_type: fileValue.type,
    file_size: fileValue.size,
    storage_bucket: "visit-documents",
    storage_path: storagePath,
    document_type: documentType,
    title: text(formData, "title") ?? fileValue.name,
    description: text(formData, "description"),
    is_visible_to_owner: checked(formData, "is_visible_to_owner"),
  });

  if (error) {
    redirect(`/clinic/visit-records/${visitRecordId}?error=unknown`);
  }

  revalidatePath(`/clinic/visit-records/${visitRecordId}`);
  redirect(`/clinic/visit-records/${visitRecordId}?success=created`);
}

export async function reportReviewPlaceholder(formData: FormData) {
  const { clinicId } = await requireClinicAccess();
  const id = text(formData, "id");

  if (!id) {
    redirect("/clinic/reviews?error=validation");
  }

  const { data: review } = await createSupabaseServerClient().from("reviews").select("id").eq("id", id).eq("clinic_id", clinicId).maybeSingle();
  if (!review) {
    redirect("/clinic/reviews?error=not_found");
  }

  redirect(`/clinic/reviews/${id}?success=reported`);
}

export async function updateReviewStatus(formData: FormData) {
  const profile = await getCurrentProfile();
  const id = text(formData, "id");
  const status = text(formData, "status");

  if (!profile || profile.role !== "platform_admin") {
    redirect("/platform-admin?error=permission");
  }

  if (!id || !status || !["pending_moderation", "published", "hidden", "reported", "removed"].includes(status)) {
    redirect("/platform/reviews?error=validation");
  }

  const { error } = await createSupabaseServerClient().from("reviews").update({ status, is_published: status === "published" }).eq("id", id);
  if (error) {
    redirect("/platform/reviews?error=unknown");
  }

  revalidatePath("/platform/reviews");
  revalidatePath("/clinic/reviews");
  redirect("/platform/reviews?success=saved");
}

export async function requestSubscriptionUpgrade(formData: FormData) {
  const { clinicId, clinicRole, profile } = await requireClinicAccess();

  if (clinicRole !== "clinic_owner") {
    redirect("/clinic/subscription?error=permission");
  }

  const planId = text(formData, "plan_id");
  if (!planId) {
    redirect("/clinic/subscription/plans?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data: plan } = await supabase
    .from("subscription_plans")
    .select("id,code,is_active,is_public")
    .eq("id", planId)
    .eq("is_active", true)
    .maybeSingle();

  if (!plan || plan.code === "free" || !plan.is_public) {
    redirect("/clinic/subscription/plans?error=validation");
  }

  const { data: pending } = await supabase
    .from("subscription_upgrade_requests")
    .select("id")
    .eq("clinic_id", clinicId)
    .eq("status", "pending")
    .maybeSingle();

  if (pending) {
    redirect("/clinic/subscription/plans?error=upgrade_pending");
  }

  const { error } = await supabase.from("subscription_upgrade_requests").insert({
    clinic_id: clinicId,
    requested_plan_id: plan.id,
    requested_by: profile.id,
    note: text(formData, "note"),
    status: "pending",
  });

  if (error) {
    redirect("/clinic/subscription/plans?error=unknown");
  }

  revalidatePath("/clinic/subscription");
  revalidatePath("/clinic/subscription/plans");
  revalidatePath("/platform/subscription-requests");
  redirect("/clinic/subscription?success=requested");
}

export async function approveSubscriptionUpgrade(formData: FormData) {
  const profile = await getCurrentProfile();
  if (!profile || profile.role !== "platform_admin") {
    redirect("/platform-admin?error=permission");
  }

  const requestId = text(formData, "request_id");
  if (!requestId) {
    redirect("/platform/subscription-requests?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data: request } = await supabase
    .from("subscription_upgrade_requests")
    .select("id,clinic_id,requested_plan_id,requested_by,status")
    .eq("id", requestId)
    .maybeSingle();

  if (!request || request.status !== "pending") {
    redirect("/platform/subscription-requests?error=not_found");
  }

  const subscriptionPayload = {
    plan_id: request.requested_plan_id,
    status: "manual",
    billing_period: "manual",
    current_period_start: new Date().toISOString(),
    cancel_at_period_end: false,
    external_provider: "manual",
    external_subscription_id: null,
  };

  const { data: existingSubscription } = await supabase
    .from("clinic_subscriptions")
    .select("id")
    .eq("clinic_id", request.clinic_id)
    .in("status", ["trialing", "active", "manual", "past_due"])
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const { error: subscriptionError } = existingSubscription
    ? await supabase
        .from("clinic_subscriptions")
        .update(subscriptionPayload)
        .eq("id", existingSubscription.id)
    : await supabase.from("clinic_subscriptions").insert({
        clinic_id: request.clinic_id,
        ...subscriptionPayload,
      });

  if (subscriptionError) {
    redirect("/platform/subscription-requests?error=unknown");
  }

  const { error } = await supabase
    .from("subscription_upgrade_requests")
    .update({ status: "approved" })
    .eq("id", request.id);

  if (error) {
    redirect("/platform/subscription-requests?error=unknown");
  }

  revalidatePath("/platform/subscription-requests");
  revalidatePath("/platform/subscriptions");
  revalidatePath("/clinic/subscription");
  redirect("/platform/subscription-requests?success=approved");
}

export async function rejectSubscriptionUpgrade(formData: FormData) {
  const profile = await getCurrentProfile();
  if (!profile || profile.role !== "platform_admin") {
    redirect("/platform-admin?error=permission");
  }

  const requestId = text(formData, "request_id");
  if (!requestId) {
    redirect("/platform/subscription-requests?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data: request } = await supabase
    .from("subscription_upgrade_requests")
    .select("id,clinic_id,requested_by,status")
    .eq("id", requestId)
    .maybeSingle();

  if (!request || request.status !== "pending") {
    redirect("/platform/subscription-requests?error=not_found");
  }

  const { error } = await supabase
    .from("subscription_upgrade_requests")
    .update({ status: "rejected", note: text(formData, "note") })
    .eq("id", requestId)
    .eq("status", "pending");

  if (error) {
    redirect("/platform/subscription-requests?error=unknown");
  }

  revalidatePath("/platform/subscription-requests");
  redirect("/platform/subscription-requests?success=rejected");
}
