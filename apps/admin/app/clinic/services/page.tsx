import { EmptyState } from "../../../components/empty-state";
import { PageHeader } from "../../../components/page-header";
import { ServiceForm } from "../../../components/service-form";
import { ServicesTable } from "../../../components/services-table";
import { StatusMessage } from "../../../components/status-message";
import { canManageClinicCatalog, getClinicManagementData } from "../../../lib/clinic-data";

export default async function ClinicServicesPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, services } = await getClinicManagementData();
  const canManage = canManageClinicCatalog(context.clinicRole);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Каталог"
        title="Послуги"
        description="Керуйте послугами, які власники тварин зможуть переглядати та бронювати."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {canManage ? <ServiceForm /> : <EmptyState title="Тільки перегляд" description="Ваша роль дозволяє переглядати послуги, але не керувати ними." />}
      {services.length > 0 ? (
        <>
          <ServicesTable services={services} canManage={canManage} />
          <section className="grid">
            {canManage ? services.map((service) => (
              <ServiceForm key={service.id} service={service} />
            )) : null}
          </section>
        </>
      ) : (
        <EmptyState
          title="Послуг ще немає"
          description="Додайте першу послугу, щоб власники тварин розуміли, що пропонує ваша клініка."
        />
      )}
    </div>
  );
}
