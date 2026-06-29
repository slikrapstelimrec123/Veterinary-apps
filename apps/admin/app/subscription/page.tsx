import { PageHeader } from "../../components/page-header";

export default function SubscriptionPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Billing later" title="Subscription" description="Prepared for future clinic plans. Payments are not implemented in MVP." />
      <section className="card">
        <h2>Free plan</h2>
        <p className="muted">The scaffold stores subscription state, but billing providers will be added only after the core MVP is validated.</p>
        <span className="status">inactive</span>
      </section>
    </div>
  );
}

