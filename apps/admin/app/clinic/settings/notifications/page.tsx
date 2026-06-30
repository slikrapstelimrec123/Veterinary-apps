import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { getNotificationPreferences, updateNotificationPreferencesAction } from "../../../../lib/notification-data";

export default async function ClinicNotificationSettingsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const prefs = await getNotificationPreferences();

  return (
    <div className="page">
      <PageHeader eyebrow="Налаштування" title="Сповіщення" description="Керуйте in-app сповіщеннями для робочого простору клініки." />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <form className="card" action={updateNotificationPreferencesAction} style={{ display: "grid", gap: 12 }}>
        <PreferenceToggle name="in_app_enabled" title="Сповіщення в кабінеті" description="Показувати важливі оновлення у кабінеті клініки." checked={prefs.in_app_enabled} />
        <PreferenceToggle name="new_appointment_alerts_enabled" title="Нові запити на запис" description="Сповіщати про нові запити від власників тварин." checked={prefs.new_appointment_alerts_enabled} />
        <PreferenceToggle name="appointment_cancellation_alerts_enabled" title="Скасування записів" description="Сповіщати, коли власник тварини скасовує запис." checked={prefs.appointment_cancellation_alerts_enabled} />
        <PreferenceToggle name="review_alerts_enabled" title="Нові відгуки" description="Сповіщати про нові відгуки після прийомів." checked={prefs.review_alerts_enabled} />
        <PreferenceToggle name="subscription_limit_alerts_enabled" title="Ліміти тарифу" description="Сповіщати, коли дія впирається в ліміт тарифу." checked={prefs.subscription_limit_alerts_enabled} />
        <div className="card" style={{ background: "var(--surface-soft)" }}>
          <h3>Канали майбутніх інтеграцій</h3>
          <p className="muted">Email, push і SMS збережені як налаштування, але зовнішні провайдери не підключені в MVP.</p>
        </div>
        <button className="button" type="submit">Зберегти</button>
      </form>
    </div>
  );
}

function PreferenceToggle({ name, title, description, checked }: { name: string; title: string; description: string; checked: boolean }) {
  return (
    <label className="card" style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16 }}>
      <span>
        <strong>{title}</strong>
        <span className="muted" style={{ display: "block", marginTop: 4 }}>{description}</span>
      </span>
      <input type="hidden" name={name} value="off" />
      <input type="checkbox" name={name} defaultChecked={checked} />
    </label>
  );
}
