import { PageHeader } from "../../components/page-header";
import { getCurrentProfile } from "../../lib/auth";

export default async function PlatformAdminPage() {
  const profile = await getCurrentProfile();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Platform"
        title="Platform admin"
        description="Placeholder for moderation and platform-level support workflows."
      />
      <section className="card">
        <h2>{profile?.full_name ?? "Platform admin"}</h2>
        <p className="muted">Role: {profile?.role ?? "unknown"}</p>
      </section>
    </div>
  );
}

