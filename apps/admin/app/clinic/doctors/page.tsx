import { DoctorCard } from "../../../components/doctor-card";
import { DoctorForm } from "../../../components/doctor-form";
import { DoctorsTable } from "../../../components/doctors-table";
import { EmptyState } from "../../../components/empty-state";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { canManageClinicCatalog, getClinicManagementData } from "../../../lib/clinic-data";

export default async function ClinicDoctorsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, doctors } = await getClinicManagementData();
  const canManage = canManageClinicCatalog(context.clinicRole);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Team"
        title="Doctors"
        description="Build clean doctor profiles before appointment booking is enabled."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {canManage ? <DoctorForm /> : <EmptyState title="View only" description="Your role can view doctor profiles but cannot manage them." />}
      {doctors.length > 0 ? (
        <>
          <DoctorsTable doctors={doctors} canManage={canManage} />
          <section className="grid">
            {doctors.map((doctor) => (
              <DoctorCard key={doctor.id} doctor={doctor} />
            ))}
          </section>
        </>
      ) : (
        <EmptyState
          title="No doctors yet"
          description="Add your first doctor to start building your clinic profile."
        />
      )}
    </div>
  );
}
