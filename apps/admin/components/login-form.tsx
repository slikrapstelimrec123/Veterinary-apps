"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createSupabaseBrowserClient } from "../lib/supabase-browser";

function friendlyAuthError(message?: string) {
  if (!message) {
    return "Unable to sign in. Please check your details.";
  }

  if (message.toLowerCase().includes("invalid")) {
    return "Email or password is incorrect.";
  }

  return "Unable to sign in. Please try again.";
}

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

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
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password });
    setIsLoading(false);

    if (authError) {
      setError(friendlyAuthError(authError.message));
      return;
    }

    router.replace(searchParams.get("next") ?? "/dashboard");
    router.refresh();
  }

  return (
    <form className="card" style={{ display: "grid", gap: 12, maxWidth: 440 }} onSubmit={handleSubmit}>
      {error ? <p style={{ color: "#9f1239", margin: 0 }}>{error}</p> : null}
      <label>
        Email
        <input value={email} onChange={(event) => setEmail(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} placeholder="clinic@example.com" />
      </label>
      <label>
        Password
        <input value={password} onChange={(event) => setPassword(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} type="password" placeholder="Password" />
      </label>
      <button className="button" type="submit" disabled={isLoading}>
        {isLoading ? "Signing in..." : "Continue"}
      </button>
    </form>
  );
}

