import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";
import { AppSidebar } from "../components/app-sidebar";
import { BetaBanner } from "../components/beta-banner";
import { LogoutButton } from "../components/logout-button";
import { NotificationDropdown } from "../components/notification-dropdown";

export const metadata: Metadata = {
  title: "VetCare Кабінет",
  description: "Кабінет клініки для ветеринарних команд",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uk">
      <body>
        <div style={{ display: "grid", gridTemplateColumns: "260px 1fr", minHeight: "100vh" }}>
          <AppSidebar />
          <main style={{ padding: 28 }}>
            <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "flex-start", gap: 8, marginBottom: 20 }}>
              <NotificationDropdown />
              <Link className="button" href="/login">Вхід</Link>
              <LogoutButton />
            </div>
            <BetaBanner />
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
