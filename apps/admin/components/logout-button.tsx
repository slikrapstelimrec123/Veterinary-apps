"use client";

import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "../lib/supabase-browser";

export function LogoutButton() {
  const router = useRouter();

  async function handleLogout() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signOut();
    router.replace("/login");
    router.refresh();
  }

  return (
    <button className="button" type="button" onClick={handleLogout}>
      Logout
    </button>
  );
}

