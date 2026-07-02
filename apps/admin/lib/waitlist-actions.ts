"use server";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase-server";

export async function joinPetOwnerWaitlist(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const name = String(formData.get("name") ?? "").trim();
  const phone = String(formData.get("phone") ?? "").trim();
  const petType = String(formData.get("pet_type") ?? "").trim();
  const consent = formData.get("consent") === "on";

  if (!email || !consent) {
    redirect("/?error=waitlist_validation");
  }

  let failed = false;

  try {
    const { error } = await createSupabaseServerClient().from("waitlist_leads").insert({
      email,
      name: name || null,
      phone: phone || null,
      pet_type: petType || null,
      source: "public_landing",
      consent,
    });

    if (error) {
      failed = true;
    }
  } catch {
    failed = true;
  }

  if (failed) {
    redirect("/?error=waitlist_unknown");
  }

  redirect("/?success=waitlist_joined");
}
