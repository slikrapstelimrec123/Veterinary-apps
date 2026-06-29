import { DoctorScheduleForm } from "../../../components/doctor-schedule-form";
import { DoctorScheduleView } from "../../../components/doctor-schedule-view";
import { EmptyState } from "../../../components/empty-state";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { canManageClinicCatalog, getClinicManagementData } from "../../../lib/clinic-data";

export default async function ClinicSchedulePage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, doctors, schedules } = await getClinicManagementData();
  const canManage = canManageClinicCatalog(context.clinicRole);
  const activeDoctors = doctors.filter((doctor) => doctor.status === "active");

  return (
    <div className="page">
      <PageHeader
        eyebrow="Доступність"
        title="Розклад лікарів"
        description="Вкажіть години роботи лікарів для майбутнього бронювання записів."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {activeDoctors.length === 0 ? (
        <EmptyState
          title="Немає активних лікарів"
          description="Додайте та активуйте лікаря, перш ніж створювати розклад."
          action={<a className="button" href="/clinic/doctors">Додати лікаря</a>}
        />
      ) : canManage ? (
        <DoctorScheduleForm doctors={activeDoctors} />
      ) : null}
      {schedules.length > 0 ? (
        <DoctorScheduleView doctors={activeDoctors} schedules={schedules} canManage={canManage} />
      ) : (
        <EmptyState
          title="Розкладів ще немає"
          description="Вкажіть години роботи лікарів, щоб клієнти могли бронювати записи."
        />
      )}
    </div>
  );
}
