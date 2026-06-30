"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { getCurrentProfile } from "./auth";
import { createSupabaseServerClient } from "./supabase-server";

function text(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

export async function submitBetaFeedback(formData: FormData) {
  const profile = await getCurrentProfile();
  if (!profile) {
    redirect("/login");
  }

  const message = text(formData, "message");
  const category = text(formData, "category") ?? "other";
  const ratingValue = text(formData, "rating");
  const rating = ratingValue ? Number(ratingValue) : null;

  if (!message || message.length < 8 || message.length > 2000 || (rating !== null && (!Number.isFinite(rating) || rating < 1 || rating > 5))) {
    redirect("/support?error=validation");
  }

  const supabase = createSupabaseServerClient();
  const { data: member } = await supabase
    .from("clinic_members")
    .select("clinic_id")
    .eq("user_id", profile.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  const { error } = await supabase.from("beta_feedback").insert({
    user_id: profile.id,
    clinic_id: member?.clinic_id ?? null,
    role: profile.role,
    rating,
    category,
    message,
    status: "new",
  });

  if (error) {
    redirect("/support?error=unknown");
  }

  revalidatePath("/support");
  redirect("/support?success=feedback_sent");
}
