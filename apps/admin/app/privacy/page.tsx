import { PageHeader } from "../../components/page-header";

export default function PrivacyPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Довіра" title="Політика конфіденційності" description="Beta placeholder. Review with legal specialist before public launch." />
      <section className="card">
        <h2>Які дані обробляються</h2>
        <p className="muted">Платформа може обробляти дані акаунта, контактні дані, інформацію про тварин, записи до клінік, медичні записи, документи та службові журнали доступу.</p>
        <h2>Медична інформація</h2>
        <p className="muted">Медичні записи та документи створюють ветеринарні клініки. Доступ до них обмежено власником тварини, відповідною клінікою та ролями, дозволеними політиками безпеки.</p>
        <h2>Видалення та запит даних</h2>
        <p className="muted">Автоматичне видалення акаунта й експорт даних є placeholder для beta. Запити обробляються через підтримку, без автоматичного видалення медичної історії.</p>
      </section>
    </div>
  );
}
