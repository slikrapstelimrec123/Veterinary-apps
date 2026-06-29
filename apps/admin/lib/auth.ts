import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase-server";
import type { UserProfile, UserRole } from "../types";

const clinicRoles: UserRole[] = ["clinic_owner", "veterinarian", "clinic_manager"];

export async function getCurrentUser() {
  const supabase = createSupabaseServerClient();
  const { data, error } = await supabase.auth.getUser();

  if (error || !data.user) {
    return null;
  }

  return data.user;
}

export async function getCurrentProfile(): Promise<UserProfile | null> {
  const user = await getCurrentUser();

  if (!user) {
    return null;
  }

  const supabase = createSupabaseServerClient();
  const { data } = await supabase
    .from("profiles")
    .select("id,email,full_name,phone,avatar_url,role")
    .eq("id", user.id)
    .maybeSingle();

  return data as UserProfile | null;
}

export async function requireAuth() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/login");
  }

  return user;
}

export async function requireClinicRole(allowedRoles: UserRole[] = clinicRoles) {
  await requireAuth();
  const profile = await getCurrentProfile();

  if (!profile) {
    redirect("/login?error=profile_missing");
  }

  if (!allowedRoles.includes(profile.role)) {
    if (profile.role === "platform_admin") {
      redirect("/platform-admin");
    }

    redirect("/login?error=admin_role_required");
  }

  return profile;
}

export async function requireClinicAccess() {
  const profile = await requireClinicRole();
  const supabase = createSupabaseServerClient();
  const { data } = await supabase
    .from("clinic_members")
    .select("clinic_id,role,status")
    .eq("user_id", profile.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (!data) {
    redirect("/login?error=clinic_access_required");
  }

  return {
    profile,
    clinicId: data.clinic_id as string,
    clinicRole: data.role as string,
  };
}

