import { PageHeader } from "../../components/page-header";
import { getCurrentProfile } from "../../lib/auth";

export default async function PlatformAdminPage() {
  const profile = await getCurrentProfile();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Платформа"
        title="Адміністратор платформи"
        description="Заготовка для модерації та робочих процесів підтримки на рівні платформи."
      />
      <section className="card">
        <h2>{profile?.full_name ?? "Адміністратор платформи"}</h2>
        <p className="muted">Роль: {profile?.role ?? "невідома"}</p>
      </section>
    </div>
  );
}

