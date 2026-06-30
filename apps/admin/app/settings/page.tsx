import { PageHeader } from "../../components/page-header";
import Link from "next/link";

export default function SettingsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Робочий простір" title="Налаштування" description="Заготовка для облікового запису клініки, команди, дозволів та конфіденційності." />
      <section className="grid">
        <div className="card"><h2>Доступ команди</h2><p className="muted">Ролі: власник клініки, ветеринар та менеджер клініки.</p></div>
        <div className="card"><h2>Конфіденційність</h2><p className="muted">Медичні записи та файли мають залишатися приватними за замовчуванням.</p></div>
        <div className="card">
          <h2>Сповіщення</h2>
          <p className="muted">Налаштуйте оновлення для записів, відгуків і лімітів тарифу.</p>
          <Link className="button button-secondary" href="/clinic/settings/notifications">Відкрити</Link>
        </div>
      </section>
    </div>
  );
}
