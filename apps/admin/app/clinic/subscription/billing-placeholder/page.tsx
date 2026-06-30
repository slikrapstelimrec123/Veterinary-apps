import Link from "next/link";
import { PageHeader } from "../../../../components/page-header";

export default function BillingPlaceholderPage() {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Оплата"
        title="Платежі ще не підключені"
        description="У MVP немає збору карток, списань, Stripe, LiqPay, WayForPay, Fondy, Apple або Google Billing."
        action={<Link className="button button-secondary" href="/clinic/subscription">Назад</Link>}
      />
      <section className="card">
        <h2>Безпечний mock-flow</h2>
        <p className="muted">
          Клініка може надіслати запит на тариф. Платформений адміністратор вручну підтверджує його в кабінеті, після чого ліміти оновлюються.
        </p>
      </section>
    </div>
  );
}
