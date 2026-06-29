import { ClinicDashboardCards } from "../../components/clinic-dashboard-cards";
import { EmptyState } from "../../components/empty-state";
import { PageHeader } from "../../components/page-header";
import { ProfileCompletionChecklist } from "../../components/profile-completion-checklist";
import { StatusMessage } from "../../components/status-message";
import { getClinicManagementData, profileCompletion } from "../../lib/clinic-data";

export default async function DashboardPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, clinic, doctors, services, schedules } = await getClinicManagementData();
  const completion = profileCompletion(clinic, services, doctors, schedules);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Overview"
        title="Clinic dashboard"
        description="A focused setup workspace for clinic profile, services, doctors, and schedules."
        action={<a className="button" href="/clinic/profile">Edit clinic profile</a>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <ClinicDashboardCards clinic={clinic} doctors={doctors} services={services} completionPercent={completion.percent} />
      <section className="grid">
        <ProfileCompletionChecklist items={completion.items} percent={completion.percent} />
        <section className="card">
          <h2>Current user</h2>
          <p className="muted">{context.profile.full_name}</p>
          <span className="status">{context.clinicRole}</span>
        </section>
      </section>
      {!clinic ? (
        <EmptyState
          title="Clinic profile not found"
          description="Your account is active, but no clinic workspace is connected yet."
        />
      ) : null}
    </div>
  );
}

