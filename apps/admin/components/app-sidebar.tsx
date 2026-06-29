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
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/clinic/profile", label: "Clinic Profile", icon: HeartPulse },
  { href: "/clinic/services", label: "Services", icon: FileText },
  { href: "/clinic/doctors", label: "Doctors", icon: Stethoscope },
  { href: "/clinic/schedule", label: "Schedule", icon: CalendarDays },
  { href: "/clients", label: "Clients", icon: Users },
  { href: "/pets", label: "Pets", icon: PawPrint },
  { href: "/appointments", label: "Appointments", icon: CalendarDays },
  { href: "/visit-records", label: "Visit Records", icon: FileText },
  { href: "/documents", label: "Documents", icon: FileText },
  { href: "/subscription", label: "Subscription", icon: WalletCards },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function AppSidebar() {
  return (
    <aside style={{ borderRight: "1px solid var(--border)", background: "var(--surface)", padding: 20 }}>
      <div style={{ marginBottom: 28 }}>
        <div style={{ fontWeight: 900, fontSize: 22 }}>VetCare</div>
        <div className="muted" style={{ marginTop: 4 }}>Clinic workspace</div>
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
