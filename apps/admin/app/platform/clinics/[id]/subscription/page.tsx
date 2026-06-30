import Link from "next/link";
import { PageHeader } from "../../../../../components/page-header";

export default function PlatformClinicSubscriptionPage({
  params,
}: {
  params: { id: string };
}) {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Платформа"
        title="Підписка клініки"
        description="Детальна ручна зміна тарифу буде розширена після появи повного платформеного каталогу клінік."
        action={<Link className="button button-secondary" href="/platform/subscription-requests">До запитів</Link>}
      />
      <section className="card">
        <h2>Клініка</h2>
        <p className="muted">{params.id}</p>
        <p className="muted">У поточному MVP підтвердження апгрейду виконується через сторінку запитів.</p>
      </section>
    </div>
  );
}
