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
        eyebrow="Команда"
        title="Лікарі"
        description="Створіть профілі лікарів до того, як буде увімкнено бронювання записів."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {canManage ? <DoctorForm /> : <EmptyState title="Тільки перегляд" description="Ваша роль дозволяє переглядати профілі лікарів, але не керувати ними." />}
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
          title="Лікарів ще немає"
          description="Додайте першого лікаря, щоб почати формувати профіль клініки."
        />
      )}
    </div>
  );
}
