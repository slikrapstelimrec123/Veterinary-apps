"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createSupabaseBrowserClient } from "../lib/supabase-browser";

function friendlyAuthError(message?: string) {
  if (!message) {
    return "Не вдалося увійти. Перевірте свої дані.";
  }

  if (message.toLowerCase().includes("invalid")) {
    return "Електронна пошта або пароль неправильні.";
  }

  return "Не вдалося увійти. Спробуйте ще раз.";
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
      setError("Введіть дійсну адресу електронної пошти.");
      return;
    }

    if (password.length < 6) {
      setError("Пароль повинен містити щонайменше 6 символів.");
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
        Електронна пошта
        <input value={email} onChange={(event) => setEmail(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} placeholder="clinic@example.com" />
      </label>
      <label>
        Пароль
        <input value={password} onChange={(event) => setPassword(event.target.value)} style={{ width: "100%", marginTop: 6, padding: 12 }} type="password" placeholder="Пароль" />
      </label>
      <button className="button" type="submit" disabled={isLoading}>
        {isLoading ? "Вхід..." : "Продовжити"}
      </button>
    </form>
  );
}

