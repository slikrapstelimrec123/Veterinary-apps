"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "../lib/supabase-browser";

export function RegisterClinicForm() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [clinicName, setClinicName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setMessage(null);

    if (fullName.trim().length < 2) {
      setError("Enter the clinic owner's full name.");
      return;
    }

    if (clinicName.trim().length < 2) {
      setError("Enter the clinic name.");
      return;
    }

    if (!email.includes("@")) {
      setError("Enter a valid email address.");
      return;
    }

    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }

    setIsLoading(true);
    const supabase = createSupabaseBrowserClient();
    const { data, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: "clinic_owner",
        },
      },
    });

    if (signUpError || !data.user) {
      setIsLoading(false);
      setError("Unable to create account. Please try again.");
      return;
    }

    const { error: profileError } = await supabase.from("profiles").insert({
      id: data.user.id,
      email,
      full_name: fullName,
      role: "clinic_owner",
    });

    if (profileError) {
      setIsLoading(false);
      setMessage("Account created. Please confirm your email, then sign in to finish clinic setup.");
      return;
    }

    const { data: clinic, error: clinicError } = await supabase
      .from("clinics")
      .insert({
        name: clinicName,
        email,
        status: "draft",
        created_by: data.user.id,
      })
      .select("id")
      .single();

    if (clinicError || !clinic) {
      setIsLoading(false);
      setError("Account created, but clinic setup could not be completed yet.");
      return;
    }

    const { error: memberError } = await supabase.from("clinic_members").insert({
      clinic_id: clinic.id,
      user_id: data.user.id,
      role: "clinic_owner",
      status: "active",
    });

    setIsLoading(false);

    if (memberError) {
      setError("Clinic created, but owner access could not be linked yet.");
      return;
    }

    router.replace("/dashboard");
    router.refresh();
  }

  return (
    <form className="card" style={{ display: "grid", gap: 12, maxWidth: 520 }} onSubmit={handleSubmit}>
      {error ? <p style={{ color: "#9f1239", margin: 0 }}>{error}</p> : null}
      {message ? <p style={{ color: "#166534", margin: 0 }}>{message}</p> : null}
      <label>
        Owner full name
        <input value={fullName} onChange={(event) => setFullName(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} />
      </label>
      <label>
        Clinic name
        <input value={clinicName} onChange={(event) => setClinicName(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} />
      </label>
      <label>
        Email
        <input value={email} onChange={(event) => setEmail(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} />
      </label>
      <label>
        Password
        <input value={password} onChange={(event) => setPassword(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} type="password" />
      </label>
      <button className="button" type="submit" disabled={isLoading}>
        {isLoading ? "Creating clinic..." : "Create clinic account"}
      </button>
    </form>
  );
}

