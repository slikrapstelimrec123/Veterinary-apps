import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { getUserNotificationCenter, markAllNotificationsAsReadAction, markNotificationAsReadAction } from "../../../lib/notification-data";

export default async function ClinicNotificationsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { notifications, unreadCount } = await getUserNotificationCenter();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Оновлення"
        title="Сповіщення"
        description="Запити на записи, скасування, відгуки, документи та важливі ліміти клініки."
        action={unreadCount > 0 ? (
          <form action={markAllNotificationsAsReadAction}>
            <button className="button button-secondary" type="submit">Позначити всі як прочитані</button>
          </form>
        ) : null}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      {notifications.length === 0 ? (
        <section className="card empty-state">
          <h2>Сповіщень поки немає</h2>
          <p className="muted">Важливі оновлення з’являться тут.</p>
        </section>
      ) : (
        <section className="card">
          <div style={{ display: "grid", gap: 12 }}>
            {notifications.map((notification) => (
              <form key={notification.id} action={markNotificationAsReadAction} style={{ borderBottom: "1px solid var(--border)", paddingBottom: 12 }}>
                <input type="hidden" name="id" value={notification.id} />
                <input type="hidden" name="return_to" value="/clinic/notifications" />
                <button
                  type="submit"
                  style={{
                    width: "100%",
                    border: 0,
                    background: notification.status === "unread" ? "var(--surface-soft)" : "transparent",
                    borderRadius: 8,
                    padding: 12,
                    textAlign: "left",
                    cursor: "pointer",
                  }}
                >
                  <span className="status">{notification.status === "unread" ? "Нове" : "Прочитано"}</span>
                  <h3 style={{ marginTop: 8 }}>{notification.title}</h3>
                  <p className="muted">{notification.body}</p>
                  <p className="muted">{new Date(notification.created_at).toLocaleString("uk-UA")}</p>
                </button>
              </form>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
