import Link from "next/link";
import { PageHeader } from "../../../../components/page-header";
import { UsageCard, usageItems } from "../../../../components/subscription-widgets";
import { getClinicSubscriptionData } from "../../../../lib/subscription-data";

export default async function SubscriptionUsagePage() {
  const { currentPlan, limits, usage } = await getClinicSubscriptionData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Використання"
        title="Ліміти та поточне навантаження"
        description={`Поточний тариф: ${currentPlan?.name ?? "Free"}. Дані рахуються динамічно з таблиць клініки.`}
        action={<Link className="button button-secondary" href="/clinic/subscription">Назад</Link>}
      />
      <section className="grid">
        {usageItems.map((item) => (
          <UsageCard key={item.key} usage={usage} limits={limits} item={item} />
        ))}
      </section>
      <section className="card">
        <h2>Як працює контроль лімітів</h2>
        <p className="muted">
          Сервер перевіряє тариф перед створенням лікаря, послуги, підтвердженням запису, створенням медичного запису та завантаженням документа.
        </p>
      </section>
    </div>
  );
}
