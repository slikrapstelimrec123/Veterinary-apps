import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { getClinicVisitRecordsData } from "../../../lib/clinic-data";
import type { VisitRecord } from "../../../types";

const statusLabels: Record<VisitRecord["status"], string> = {
  draft: "Чернетка",
  published: "Опубліковано",
  archived: "Архів",
};

export default async function ClinicVisitRecordsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { records } = await getClinicVisitRecordsData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Медична картка"
        title="Історія візитів"
        description="Діагнози, лікування, рекомендації та приватні документи, пов'язані з візитами тварин."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {records.length === 0 ? (
        <section className="card empty-state">
          <h2>Записів ще немає</h2>
          <p className="muted">Створіть медичний запис із підтвердженого або завершеного appointment.</p>
          <Link className="button" href="/clinic/appointments">Перейти до записів</Link>
        </section>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Дата</th>
              <th>Тварина</th>
              <th>Діагноз</th>
              <th>Документи</th>
              <th>Статус</th>
              <th>Дія</th>
            </tr>
          </thead>
          <tbody>
            {records.map((record) => (
              <tr key={record.id}>
                <td>{formatDate(record.visit_date)}</td>
                <td>
                  <strong>{record.pets?.name ?? "Тварина"}</strong>
                  <br />
                  <span className="muted">{record.profiles?.full_name ?? record.profiles?.email ?? "Власник"}</span>
                </td>
                <td>{record.diagnosis ?? record.reason_for_visit ?? "Без діагнозу"}</td>
                <td>{record.visit_documents?.length ?? 0}</td>
                <td><span className="status">{statusLabels[record.status]}</span></td>
                <td><Link className="button button-secondary" href={`/clinic/visit-records/${record.id}`}>Деталі</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
