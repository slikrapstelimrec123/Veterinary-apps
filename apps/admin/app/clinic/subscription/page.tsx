import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { PlanLimitList, UsageCard, formatBillingPeriod, formatSubscriptionStatus, usageItems } from "../../../components/subscription-widgets";
import { getClinicSubscriptionData } from "../../../lib/subscription-data";

export default async function ClinicSubscriptionPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { currentPlan, subscription, limits, usage, pendingRequest } = await getClinicSubscriptionData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="SaaS"
        title="Підписка клініки"
        description="Керуйте тарифом, лімітами та заявкою на ручне підключення платного плану."
        action={<Link className="button" href="/clinic/subscription/plans">Переглянути тарифи</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        <article className="card">
          <p className="eyebrow">Поточний тариф</p>
          <h2>{currentPlan?.name ?? "Free"}</h2>
          <p className="muted">{currentPlan?.description ?? "Базовий тариф для MVP."}</p>
          <div className="form-actions">
            <span className="status">{formatSubscriptionStatus(subscription?.status)}</span>
            <span className="status">{formatBillingPeriod(subscription?.billing_period)}</span>
          </div>
          {subscription?.trial_ends_at ? <p className="muted">Тріал до {new Date(subscription.trial_ends_at).toLocaleDateString("uk-UA")}</p> : null}
        </article>

        <article className="card">
          <p className="eyebrow">Зміна тарифу</p>
          <h2>{pendingRequest ? "Запит очікує" : "Ручна активація"}</h2>
          <p className="muted">
            {pendingRequest
              ? "Платформений адміністратор має підтвердити запит. Дані картки не збираються."
              : "Платежі ще не підключені, тому апгрейд працює через безпечний запит на ручну активацію."}
          </p>
          <Link className="button button-secondary" href="/clinic/subscription/billing-placeholder">Оплата в MVP</Link>
        </article>
      </section>

      <section>
        <PageHeader eyebrow="Використання" title="Поточні ліміти" description="Показники рахуються з наявних даних клініки." action={<Link className="button button-secondary" href="/clinic/subscription/usage">Детально</Link>} />
        <div className="grid">
          {usageItems.map((item) => (
            <UsageCard key={item.key} usage={usage} limits={limits} item={item} />
          ))}
        </div>
      </section>

      <section className="card">
        <h2>Можливості тарифу</h2>
        <PlanLimitList limits={limits} />
      </section>
    </div>
  );
}
