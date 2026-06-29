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
        eyebrow="Availability"
        title="Doctor schedule"
        description="Set doctor availability for future appointment booking."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {activeDoctors.length === 0 ? (
        <EmptyState
          title="No active doctors"
          description="Add and activate a doctor before creating availability."
          action={<a className="button" href="/clinic/doctors">Add doctor</a>}
        />
      ) : canManage ? (
        <DoctorScheduleForm doctors={activeDoctors} />
      ) : null}
      {schedules.length > 0 ? (
        <DoctorScheduleView doctors={activeDoctors} schedules={schedules} canManage={canManage} />
      ) : (
        <EmptyState
          title="No schedules yet"
          description="Set doctor availability so clients can book appointments later."
        />
      )}
    </div>
  );
}
