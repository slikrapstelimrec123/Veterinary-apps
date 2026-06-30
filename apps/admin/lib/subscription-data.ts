import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase-server";
import { getCurrentProfile, requireClinicAccess } from "./auth";
import type { ClinicSubscription, SubscriptionPlan, SubscriptionPlanLimits, SubscriptionUpgradeRequest, SubscriptionUsage } from "../types";

export type SubscriptionContext = Awaited<ReturnType<typeof getClinicSubscriptionData>>;

const defaultUsage: SubscriptionUsage = {
  doctors_count: 0,
  services_count: 0,
  appointments_count: 0,
  visit_records_count: 0,
  documents_count: 0,
  storage_used_mb: 0,
};

export async function getPublicPlans() {
  const plans = await createSupabaseServerClient()
    .from("subscription_plans")
    .select("*")
    .eq("is_active", true)
    .eq("is_public", true)
    .order("sort_order", { ascending: true });

  return (plans.data ?? []) as SubscriptionPlan[];
}

export async function getClinicSubscriptionData() {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();
  const [plansResult, subscriptionResult, usageResult, requestsResult] = await Promise.all([
    supabase.from("subscription_plans").select("*").eq("is_active", true).eq("is_public", true).order("sort_order", { ascending: true }),
    supabase
      .from("clinic_subscriptions")
      .select("*, subscription_plans(*)")
      .eq("clinic_id", context.clinicId)
      .in("status", ["trialing", "active", "manual", "past_due"])
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase.rpc("get_clinic_usage", { target_clinic_id: context.clinicId }),
    supabase
      .from("subscription_upgrade_requests")
      .select("*, subscription_plans(*)")
      .eq("clinic_id", context.clinicId)
      .order("created_at", { ascending: false }),
  ]);

  const plans = (plansResult.data ?? []) as SubscriptionPlan[];
  const subscription = subscriptionResult.data as ClinicSubscription | null;
  const currentPlan = subscription?.subscription_plans ?? plans.find((plan) => plan.code === "free") ?? null;
  const usage = ((usageResult.data as SubscriptionUsage[] | null)?.[0] ?? defaultUsage) as SubscriptionUsage;
  const requests = (requestsResult.data ?? []) as SubscriptionUpgradeRequest[];

  return {
    context,
    plans,
    subscription,
    currentPlan,
    limits: (currentPlan?.limits ?? {}) as SubscriptionPlanLimits,
    usage,
    requests,
    pendingRequest: requests.find((request) => request.status === "pending") ?? null,
  };
}

export async function getSubscriptionGate(clinicId: string) {
  const supabase = createSupabaseServerClient();
  const [limitsResult, usageResult] = await Promise.all([
    supabase.rpc("get_clinic_plan_limits", { target_clinic_id: clinicId }),
    supabase.rpc("get_clinic_usage", { target_clinic_id: clinicId }),
  ]);

  return {
    limits: (limitsResult.data ?? {}) as SubscriptionPlanLimits,
    usage: ((usageResult.data as SubscriptionUsage[] | null)?.[0] ?? defaultUsage) as SubscriptionUsage,
  };
}

export function limitReached(current: number, max: number | undefined) {
  if (max === undefined || max === null) {
    return true;
  }

  return max >= 0 && current >= max;
}

export function usagePercent(current: number, max: number | undefined) {
  if (!max || max < 0) {
    return 0;
  }

  return Math.min(100, Math.round((current / max) * 100));
}

export async function requirePlanCapacity(clinicId: string, kind: "doctor" | "service" | "appointment" | "visit_record" | "document", fileSizeBytes = 0) {
  const supabase = createSupabaseServerClient();
  const rpc = {
    doctor: "can_clinic_add_doctor",
    service: "can_clinic_add_service",
    appointment: "can_clinic_create_appointment",
    visit_record: "can_clinic_create_visit_record",
    document: "can_clinic_upload_document",
  }[kind];

  const params = kind === "document" ? { target_clinic_id: clinicId, file_size_bytes: fileSizeBytes } : { target_clinic_id: clinicId };
  const { data } = await supabase.rpc(rpc, params);

  if (data !== true) {
    await supabase.rpc("notify_subscription_limit_warning", { target_clinic_id: clinicId, limit_code: kind });
    redirect(kind === "appointment" ? "/clinic/appointments?error=limit_reached" : kind === "visit_record" ? "/clinic/visit-records?error=limit_reached" : "/clinic/subscription?error=limit_reached");
  }
}

export async function canClinicAcceptOnlineBooking(clinicId: string) {
  const { data } = await createSupabaseServerClient().rpc("can_clinic_create_appointment", { target_clinic_id: clinicId });
  return data === true;
}

export async function getPlatformSubscriptionRequests() {
  const profile = await getCurrentProfile();
  if (!profile || profile.role !== "platform_admin") {
    return { profile, requests: [] as SubscriptionUpgradeRequest[] };
  }

  const { data } = await createSupabaseServerClient()
    .from("subscription_upgrade_requests")
    .select("*, clinics(id,name), subscription_plans(*), profiles(id,full_name,email)")
    .order("created_at", { ascending: false });

  return { profile, requests: (data ?? []) as SubscriptionUpgradeRequest[] };
}
