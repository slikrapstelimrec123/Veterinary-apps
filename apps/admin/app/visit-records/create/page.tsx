import { PageHeader } from "../../../components/page-header";

export default function CreateVisitRecordPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Medical record" title="Create visit record" description="Draft form for diagnosis, treatment notes, recommendations, and internal notes." action={<button className="button">Save draft</button>} />
      <form className="card" style={{ display: "grid", gap: 12 }}>
        <label>Diagnosis<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Treatment notes<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Recommendations<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Internal notes<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
      </form>
    </div>
  );
}

