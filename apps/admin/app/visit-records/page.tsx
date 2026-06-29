import { PageHeader } from "../../components/page-header";
import { visitRecords } from "../../lib/placeholder-data";

export default function VisitRecordsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Medical records" title="Visit records" description="Diagnoses, treatment notes, recommendations, and internal notes." action={<a className="button" href="/visit-records/create">Create record</a>} />
      <table className="table">
        <thead>
          <tr><th>Pet</th><th>Diagnosis</th><th>Status</th></tr>
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

