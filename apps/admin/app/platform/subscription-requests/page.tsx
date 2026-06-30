import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { formatSubscriptionStatus } from "../../../components/subscription-widgets";
import { approveSubscriptionUpgrade, rejectSubscriptionUpgrade } from "../../../lib/clinic-actions";
import { getPlatformSubscriptionRequests } from "../../../lib/subscription-data";

export default async function PlatformSubscriptionRequestsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { profile, requests } = await getPlatformSubscriptionRequests();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Платформа"
        title="Запити на тарифи"
        description="Ручне підтвердження тарифів для MVP без платіжного провайдера."
        action={<Link className="button button-secondary" href="/platform/subscriptions">Підписки</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      {profile?.role !== "platform_admin" ? (
        <section className="card">
          <h2>Немає доступу</h2>
          <p className="muted">Ця сторінка доступна тільки платформеному адміністратору.</p>
        </section>
      ) : requests.length === 0 ? (
        <section className="card empty-state">
          <h2>Запитів немає</h2>
          <p className="muted">Коли клініка запросить апгрейд тарифу, він з'явиться тут.</p>
        </section>
      ) : (
        <section className="card">
          <table className="table">
            <thead>
              <tr>
                <th>Клініка</th>
                <th>Тариф</th>
                <th>Статус</th>
                <th>Запитувач</th>
                <th>Дії</th>
              </tr>
            </thead>
            <tbody>
              {requests.map((request) => (
                <tr key={request.id}>
                  <td>{request.clinics?.name ?? request.clinic_id}</td>
                  <td>{request.subscription_plans?.name ?? request.requested_plan_id}</td>
                  <td><span className="status">{formatSubscriptionStatus(request.status)}</span></td>
                  <td>{request.profiles?.full_name ?? request.profiles?.email ?? request.requested_by}</td>
                  <td>
                    {request.status === "pending" ? (
                      <div className="form-actions">
                        <form action={approveSubscriptionUpgrade}>
                          <input type="hidden" name="request_id" value={request.id} />
                          <button className="button" type="submit">Підтвердити</button>
                        </form>
                        <form action={rejectSubscriptionUpgrade}>
                          <input type="hidden" name="request_id" value={request.id} />
                          <button className="button button-danger" type="submit">Відхилити</button>
                        </form>
                      </div>
                    ) : (
                      <span className="muted">Оброблено</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </div>
  );
}
