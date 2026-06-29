import { PageHeader } from "../../components/page-header";

export default function SettingsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Workspace" title="Settings" description="Clinic account, team, permissions, and privacy settings placeholder." />
      <section className="grid">
        <div className="card"><h2>Team access</h2><p className="muted">Clinic owner, veterinarian, and clinic manager roles.</p></div>
        <div className="card"><h2>Privacy</h2><p className="muted">Medical records and files must remain private by default.</p></div>
      </section>
    </div>
  );
}
