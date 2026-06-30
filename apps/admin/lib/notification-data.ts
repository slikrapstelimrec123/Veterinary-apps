import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createSupabaseServerClient } from "./supabase-server";
import { getCurrentProfile, requireAuth } from "./auth";
import type { NotificationItem, NotificationPreferences } from "../types";

const defaultPreferenceFlags = {
  in_app_enabled: true,
  email_enabled: false,
  push_enabled: false,
  sms_enabled: false,
  appointment_reminders_enabled: true,
  treatment_updates_enabled: true,
  review_requests_enabled: true,
  new_appointment_alerts_enabled: true,
  appointment_cancellation_alerts_enabled: true,
  review_alerts_enabled: true,
  subscription_limit_alerts_enabled: true,
  marketing_enabled: false,
};

function bool(formData: FormData, key: keyof typeof defaultPreferenceFlags) {
  return formData.getAll(key).includes("on");
}

function formHas(formData: FormData, key: keyof typeof defaultPreferenceFlags) {
  return formData.has(key);
}

function notificationTarget(notification: NotificationItem) {
  if (notification.appointment_id) {
    return `/clinic/appointments/${notification.appointment_id}`;
  }
  if (notification.visit_record_id) {
    return `/clinic/visit-records/${notification.visit_record_id}`;
  }
  if (notification.review_id) {
    return `/clinic/reviews/${notification.review_id}`;
  }
  if (notification.type === "subscription_limit_warning" || notification.type === "subscription_upgrade_request_status") {
    return "/clinic/subscription";
  }
  return "/clinic/notifications";
}

export async function getUserNotificationCenter(limit = 50) {
  await requireAuth();
  const profile = await getCurrentProfile();

  if (!profile) {
    redirect("/login");
  }

  const supabase = createSupabaseServerClient();
  const [notificationsResult, countResult] = await Promise.all([
    supabase
      .from("notifications")
      .select("*")
      .eq("recipient_user_id", profile.id)
      .neq("status", "archived")
      .order("created_at", { ascending: false })
      .limit(limit),
    supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("recipient_user_id", profile.id)
      .eq("status", "unread"),
  ]);

  return {
    profile,
    notifications: (notificationsResult.data ?? []) as NotificationItem[],
    unreadCount: countResult.count ?? 0,
  };
}

export async function getNotificationPreferences() {
  await requireAuth();
  const profile = await getCurrentProfile();

  if (!profile) {
    redirect("/login");
  }

  const supabase = createSupabaseServerClient();
  await supabase.from("notification_preferences").upsert({ user_id: profile.id, ...defaultPreferenceFlags }, { onConflict: "user_id", ignoreDuplicates: true });
  const { data } = await supabase.from("notification_preferences").select("*").eq("user_id", profile.id).maybeSingle();

  return (data ?? { user_id: profile.id, ...defaultPreferenceFlags }) as NotificationPreferences;
}

export async function markNotificationAsReadAction(formData: FormData) {
  const id = formData.get("id");
  const returnTo = typeof formData.get("return_to") === "string" ? String(formData.get("return_to")) : "/clinic/notifications";

  if (typeof id !== "string" || !id) {
    redirect(`${returnTo}?error=validation`);
  }

  const { data: notification } = await createSupabaseServerClient()
    .from("notifications")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  await createSupabaseServerClient().rpc("mark_notification_read", { target_notification_id: id });
  revalidatePath("/clinic/notifications");
  revalidatePath("/clinic/settings/notifications");
  redirect(notification ? notificationTarget(notification as NotificationItem) : returnTo);
}

export async function markAllNotificationsAsReadAction() {
  await createSupabaseServerClient().rpc("mark_all_notifications_read");
  revalidatePath("/clinic/notifications");
  redirect("/clinic/notifications?success=saved");
}

export async function updateNotificationPreferencesAction(formData: FormData) {
  const profile = await getCurrentProfile();
  if (!profile) {
    redirect("/login");
  }

  const existing = await getNotificationPreferences();
  const payload = {
    user_id: profile.id,
    in_app_enabled: formHas(formData, "in_app_enabled") ? bool(formData, "in_app_enabled") : existing.in_app_enabled,
    email_enabled: formHas(formData, "email_enabled") ? bool(formData, "email_enabled") : existing.email_enabled,
    push_enabled: formHas(formData, "push_enabled") ? bool(formData, "push_enabled") : existing.push_enabled,
    sms_enabled: formHas(formData, "sms_enabled") ? bool(formData, "sms_enabled") : existing.sms_enabled,
    appointment_reminders_enabled: formHas(formData, "appointment_reminders_enabled") ? bool(formData, "appointment_reminders_enabled") : existing.appointment_reminders_enabled,
    treatment_updates_enabled: formHas(formData, "treatment_updates_enabled") ? bool(formData, "treatment_updates_enabled") : existing.treatment_updates_enabled,
    review_requests_enabled: formHas(formData, "review_requests_enabled") ? bool(formData, "review_requests_enabled") : existing.review_requests_enabled,
    new_appointment_alerts_enabled: formHas(formData, "new_appointment_alerts_enabled") ? bool(formData, "new_appointment_alerts_enabled") : existing.new_appointment_alerts_enabled,
    appointment_cancellation_alerts_enabled: formHas(formData, "appointment_cancellation_alerts_enabled") ? bool(formData, "appointment_cancellation_alerts_enabled") : existing.appointment_cancellation_alerts_enabled,
    review_alerts_enabled: formHas(formData, "review_alerts_enabled") ? bool(formData, "review_alerts_enabled") : existing.review_alerts_enabled,
    subscription_limit_alerts_enabled: formHas(formData, "subscription_limit_alerts_enabled") ? bool(formData, "subscription_limit_alerts_enabled") : existing.subscription_limit_alerts_enabled,
    marketing_enabled: false,
  };

  const { error } = await createSupabaseServerClient().from("notification_preferences").upsert(payload, { onConflict: "user_id" });
  if (error) {
    redirect("/clinic/settings/notifications?error=unknown");
  }

  revalidatePath("/clinic/settings/notifications");
  redirect("/clinic/settings/notifications?success=saved");
}
