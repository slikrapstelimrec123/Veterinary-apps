import { ClinicProfileForm } from "../../../components/clinic-profile-form";
import { EmptyState } from "../../../components/empty-state";
import { PageHeader } from "../../../components/page-header";
import { ProfileCompletionChecklist } from "../../../components/profile-completion-checklist";
import { StatusMessage } from "../../../components/status-message";
import { canManageClinicProfile, getClinicManagementData, profileCompletion } from "../../../lib/clinic-data";

export default async function ClinicProfilePage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, clinic, services, doctors, schedules } = await getClinicManagementData();
  const completion = profileCompletion(clinic, services, doctors, schedules);
  const canEdit = canManageClinicProfile(context.clinicRole);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Клініка"
        title="Профіль клініки"
        description="Публічна інформація про клініку та готовність до публікації."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {clinic ? (
        <>
          <ClinicProfileForm clinic={clinic} canEdit={canEdit} />
          <ProfileCompletionChecklist items={completion.items} percent={completion.percent} />
        </>
      ) : (
        <EmptyState title="Профіль клініки відсутній" description="Попросіть власника клініки завершити реєстрацію робочого простору." />
      )}
    </div>
  );
}

