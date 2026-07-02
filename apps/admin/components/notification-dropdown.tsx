import Link from "next/link";
import { Bell } from "lucide-react";
import { getCurrentProfile } from "../lib/auth";
import { markNotificationAsReadAction } from "../lib/notification-data";
import { createSupabaseServerClient } from "../lib/supabase-server";
import type { NotificationItem } from "../types";

export async function NotificationDropdown() {
  const profile = await getCurrentProfile();
  if (!profile) {
    return null;
  }

  const supabase = createSupabaseServerClient();
  const [notificationsResult, countResult] = await Promise.all([
    supabase
      .from("notifications")
      .select("*")
      .eq("recipient_user_id", profile.id)
      .neq("status", "archived")
      .order("created_at", { ascending: false })
      .limit(5),
    supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("recipient_user_id", profile.id)
      .eq("status", "unread"),
  ]);

  const notifications = (notificationsResult.data ?? []) as NotificationItem[];
  const unreadCount = countResult.count ?? 0;

  return (
    <section className="card" style={{ padding: 10, minWidth: 280 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
        <strong style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
          <Bell size={16} />
          Сповіщення
        </strong>
        <Link className="status" href="/clinic/notifications">
          {unreadCount > 0 ? `${unreadCount} нових` : "Немає нових"}
        </Link>
      </div>
      <div style={{ display: "grid", gap: 8, marginTop: 10 }}>
        {notifications.length === 0 ? (
          <p className="muted" style={{ margin: 0 }}>Важливі оновлення зʼявляться тут.</p>
        ) : (
          notifications.map((notification) => (
            <form key={notification.id} action={markNotificationAsReadAction} style={{ display: "grid", gap: 4 }}>
              <input type="hidden" name="id" value={notification.id} />
              <input type="hidden" name="return_to" value="/clinic/notifications" />
              <button
                type="submit"
                style={{
                  border: 0,
                  background: notification.status === "unread" ? "var(--surface-soft)" : "transparent",
                  borderRadius: 8,
                  padding: 10,
                  textAlign: "left",
                  cursor: "pointer",
                }}
              >
                <strong>{notification.title}</strong>
                <span className="muted" style={{ display: "block", marginTop: 4 }}>{notification.body}</span>
              </button>
            </form>
          ))
        )}
      </div>
    </section>
  );
}
