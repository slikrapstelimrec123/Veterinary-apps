import { PageHeader } from "../../components/page-header";

export default function SubscriptionPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Оплата пізніше" title="Підписка" description="Підготовлено для майбутніх тарифних планів клінік. Платежі не реалізовано в MVP." />
      <section className="card">
        <h2>Безкоштовний план</h2>
        <p className="muted">Каркас зберігає стан підписки, але постачальники платежів будуть додані лише після валідації основного MVP.</p>
        <span className="status">inactive</span>
      </section>
    </div>
  );
}

