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
        eyebrow="Catalog"
        title="Services"
        description="Manage the services pet owners will later see and book."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {canManage ? <ServiceForm /> : <EmptyState title="View only" description="Your role can view services but cannot manage them." />}
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
          title="No services yet"
          description="Add your first service so pet owners can understand what your clinic offers."
        />
      )}
    </div>
  );
}
