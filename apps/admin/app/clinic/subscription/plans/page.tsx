import Link from "next/link";
import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { PlanLimitList, formatPrice } from "../../../../components/subscription-widgets";
import { requestSubscriptionUpgrade } from "../../../../lib/clinic-actions";
import { getClinicSubscriptionData } from "../../../../lib/subscription-data";

export default async function SubscriptionPlansPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { plans, currentPlan, pendingRequest } = await getClinicSubscriptionData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Тарифи"
        title="Плани для клінік"
        description="Ліміти зберігаються в базі даних і перевіряються сервером перед важливими діями."
        action={<Link className="button button-secondary" href="/clinic/subscription">Назад</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        {plans.map((plan) => {
          const isCurrent = currentPlan?.id === plan.id;
          const canRequest = !isCurrent && !pendingRequest && plan.code !== "free";

          return (
            <article className="card" key={plan.id}>
              <p className="eyebrow">Тариф</p>
              <h2>{plan.name}</h2>
              <p className="muted">{plan.description}</p>
              <h3>{formatPrice(plan)} <span className="muted" style={{ fontSize: 14 }}>/ місяць</span></h3>
              <p className="muted">Рік: {formatPrice(plan, true)}</p>

              {Array.isArray(plan.features) && plan.features.length > 0 ? (
                <ul>
                  {plan.features.map((feature) => (
                    <li key={feature}>{feature}</li>
                  ))}
                </ul>
              ) : null}

              <PlanLimitList limits={plan.limits} />

              {isCurrent ? (
                <span className="button button-muted">Поточний тариф</span>
              ) : canRequest ? (
                <form action={requestSubscriptionUpgrade} className="form-actions">
                  <input type="hidden" name="plan_id" value={plan.id} />
                  <button className="button" type="submit">{plan.code === "enterprise" ? "Запросити Enterprise" : "Запросити апгрейд"}</button>
                </form>
              ) : (
                <span className="button button-muted">{pendingRequest ? "Запит вже надіслано" : "Недоступно"}</span>
              )}
            </article>
          );
        })}
      </section>
    </div>
  );
}
