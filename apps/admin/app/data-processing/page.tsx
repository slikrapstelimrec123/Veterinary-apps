import { PageHeader } from "../../components/page-header";

export default function DataProcessingPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Дані" title="Обробка даних" description="Beta placeholder для майбутньої угоди з клініками. Review with legal specialist before public launch." />
      <section className="card">
        <h2>Ролі сторін</h2>
        <p className="muted">Клініка керує медичними записами, які створює для пацієнтів. Платформа забезпечує технічне зберігання, доступи та робочі процеси.</p>
        <h2>Доступи</h2>
        <p className="muted">Доступ до медичних даних обмежується Row Level Security, ролями клініки та власністю тварини.</p>
      </section>
    </div>
  );
}
