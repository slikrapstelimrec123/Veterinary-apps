import { PageHeader } from "../../components/page-header";

export default function DocumentsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Files" title="Documents" description="Private medical files attached to completed or draft visit records." action={<button className="button">Upload document</button>} />
      <section className="grid">
        <div className="card">
          <h2>Vaccination certificate</h2>
          <p className="muted">Private file. Signed URLs will be generated only after access checks.</p>
        </div>
        <div className="card">
          <h2>Lab result photo</h2>
          <p className="muted">Connected to Luna's preventive checkup.</p>
        </div>
      </section>
    </div>
  );
}

