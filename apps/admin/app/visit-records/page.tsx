import { PageHeader } from "../../components/page-header";
import { visitRecords } from "../../lib/placeholder-data";

export default function VisitRecordsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Медичні записи" title="Історія візитів" description="Діагнози, нотатки про лікування, рекомендації та внутрішні нотатки." action={<a className="button" href="/visit-records/create">Створити запис</a>} />
      <table className="table">
        <thead>
          <tr><th>Тварина</th><th>Діагноз</th><th>Статус</th></tr>
        </thead>
        <tbody>
          {visitRecords.map((record) => (
            <tr key={record.id}>
              <td>{record.petId}</td>
              <td>{record.diagnosis}</td>
              <td><span className="status">{record.status}</span></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

