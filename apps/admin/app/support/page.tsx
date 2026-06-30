import { PageHeader } from "../../components/page-header";
import { StatusMessage } from "../../components/status-message";
import { submitBetaFeedback } from "../../lib/beta-feedback-actions";

export default function SupportPage({ searchParams }: { searchParams: { success?: string; error?: string } }) {
  return (
    <div className="page">
      <PageHeader eyebrow="Beta" title="Підтримка та відгук" description="Надішліть beta-команді помилку, ідею або питання щодо даних." />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <form className="card" action={submitBetaFeedback} style={{ display: "grid", gap: 14 }}>
        <label className="field">
          <span>Категорія</span>
          <select name="category" defaultValue="bug">
            <option value="bug">Помилка</option>
            <option value="usability">Зручність</option>
            <option value="feature_request">Побажання</option>
            <option value="data_issue">Проблема з даними</option>
            <option value="other">Інше</option>
          </select>
        </label>
        <label className="field">
          <span>Оцінка beta-досвіду</span>
          <select name="rating" defaultValue="">
            <option value="">Без оцінки</option>
            <option value="5">5 - добре</option>
            <option value="4">4</option>
            <option value="3">3</option>
            <option value="2">2</option>
            <option value="1">1 - критично</option>
          </select>
        </label>
        <label className="field">
          <span>Повідомлення</span>
          <textarea name="message" required minLength={8} maxLength={2000} placeholder="Опишіть, що сталося або що варто покращити." />
        </label>
        <button className="button" type="submit">Надіслати</button>
      </form>
      <section className="grid">
        <a className="card" href="/privacy"><h2>Приватність</h2><p className="muted">Як ми описуємо дані в beta.</p></a>
        <a className="card" href="/terms"><h2>Умови</h2><p className="muted">Beta-умови використання.</p></a>
        <a className="card" href="/data-processing"><h2>Обробка даних</h2><p className="muted">Placeholder для клінік.</p></a>
      </section>
    </div>
  );
}
