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
        eyebrow="Огляд"
        title="Дашборд клініки"
        description="Робочий простір для налаштування профілю клініки, послуг, лікарів та розкладів."
        action={<a className="button" href="/clinic/profile">Редагувати профіль клініки</a>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <ClinicDashboardCards clinic={clinic} doctors={doctors} services={services} completionPercent={completion.percent} />
      <section className="grid">
        <ProfileCompletionChecklist items={completion.items} percent={completion.percent} />
        <section className="card">
          <h2>Поточний користувач</h2>
          <p className="muted">{context.profile.full_name}</p>
          <span className="status">{context.clinicRole}</span>
        </section>
      </section>
      {!clinic ? (
        <EmptyState
          title="Профіль клініки не знайдено"
          description="Ваш обліковий запис активний, але робочий простір клініки ще не підключено."
        />
      ) : null}
    </div>
  );
}

