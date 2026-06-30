import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { getPublicPlans, getPlatformSubscriptionRequests } from "../../../lib/subscription-data";

export default async function PlatformSubscriptionsPage() {
  const [{ profile, requests }, plans] = await Promise.all([getPlatformSubscriptionRequests(), getPublicPlans()]);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Платформа"
        title="Підписки клінік"
        description="MVP-огляд тарифів і заявок. Реальні платежі будуть підключені окремим етапом."
        action={<Link className="button" href="/platform/subscription-requests">Запити</Link>}
      />

      {profile?.role !== "platform_admin" ? (
        <section className="card">
          <h2>Немає доступу</h2>
          <p className="muted">Ця сторінка доступна тільки платформеному адміністратору.</p>
        </section>
      ) : (
        <section className="grid">
          <article className="card">
            <p className="eyebrow">Тарифи</p>
            <h2>{plans.length}</h2>
            <p className="muted">Активні публічні плани в базі даних.</p>
          </article>
          <article className="card">
            <p className="eyebrow">Очікують</p>
            <h2>{requests.filter((request) => request.status === "pending").length}</h2>
            <p className="muted">Запити клінік на ручний апгрейд.</p>
          </article>
        </section>
      )}
    </div>
  );
}
