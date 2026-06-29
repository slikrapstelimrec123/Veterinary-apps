import Link from "next/link";
import {
  CalendarDays,
  FileText,
  HeartPulse,
  LayoutDashboard,
  PawPrint,
  Settings,
  Stethoscope,
  Users,
  WalletCards,
} from "lucide-react";

const links = [
  { href: "/dashboard", label: "Дашборд", icon: LayoutDashboard },
  { href: "/clinic/profile", label: "Профіль клініки", icon: HeartPulse },
  { href: "/clinic/services", label: "Послуги", icon: FileText },
  { href: "/clinic/doctors", label: "Лікарі", icon: Stethoscope },
  { href: "/clinic/schedule", label: "Розклад", icon: CalendarDays },
  { href: "/clients", label: "Клієнти", icon: Users },
  { href: "/pets", label: "Тварини", icon: PawPrint },
  { href: "/appointments", label: "Записи", icon: CalendarDays },
  { href: "/visit-records", label: "Історія візитів", icon: FileText },
  { href: "/documents", label: "Документи", icon: FileText },
  { href: "/subscription", label: "Підписка", icon: WalletCards },
  { href: "/settings", label: "Налаштування", icon: Settings },
];

export function AppSidebar() {
  return (
    <aside style={{ borderRight: "1px solid var(--border)", background: "var(--surface)", padding: 20 }}>
      <div style={{ marginBottom: 28 }}>
        <div style={{ fontWeight: 900, fontSize: 22 }}>VetCare</div>
        <div className="muted" style={{ marginTop: 4 }}>Робочий простір клініки</div>
      </div>
      <nav style={{ display: "grid", gap: 6 }}>
        {links.map((link) => {
          const Icon = link.icon;
          return (
            <Link
              key={link.href}
              href={link.href}
              style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 12px", borderRadius: 8 }}
            >
              <Icon size={18} />
              <span>{link.label}</span>
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
