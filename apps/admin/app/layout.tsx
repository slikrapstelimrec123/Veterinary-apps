import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";
import { AppSidebar } from "../components/app-sidebar";
import { LogoutButton } from "../components/logout-button";

export const metadata: Metadata = {
  title: "VetCare Admin",
  description: "Панель адміністратора клініки для ветеринарних команд",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <div style={{ display: "grid", gridTemplateColumns: "260px 1fr", minHeight: "100vh" }}>
          <AppSidebar />
          <main style={{ padding: 28 }}>
            <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 20 }}>
              <Link className="button" href="/login">Вхід</Link>
              <div style={{ width: 8 }} />
              <LogoutButton />
            </div>
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
