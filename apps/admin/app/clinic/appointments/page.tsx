import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { updateAppointmentStatus } from "../../../lib/clinic-actions";
import { canManageClinicAppointments, getClinicAppointmentsData } from "../../../lib/clinic-data";
import type { Appointment } from "../../../types";

const statusLabels: Record<Appointment["status"], string> = {
  pending: "Очікує",
  confirmed: "Підтверджено",
  completed: "Завершено",
  cancelled_by_owner: "Скасовано власником",
  cancelled_by_clinic: "Скасовано клінікою",
  no_show: "Не прийшли",
};

export default async function ClinicAppointmentsPage({
  searchParams,
}: {
  searchParams: { success?: string; error?: string };
}) {
  const { context, appointments } = await getClinicAppointmentsData();
  const canManage = canManageClinicAppointments(context.clinicRole);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Календар"
        title="Записи"
        description="Переглядайте записи власників тварин, підтверджуйте час і ведіть простий операційний список для клініки."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      {appointments.length === 0 ? (
        <section className="card empty-state">
          <h2>Записів ще немає</h2>
          <p className="muted">Коли власники тварин забронюють візит у мобільному застосунку, записи з'являться тут.</p>
        </section>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Дата і час</th>
              <th>Тварина</th>
              <th>Послуга</th>
              <th>Лікар</th>
              <th>Статус</th>
              <th>Дія</th>
            </tr>
          </thead>
          <tbody>
            {appointments.map((appointment) => (
              <tr key={appointment.id}>
                <td>
                  <strong>{formatDate(appointment.appointment_date)}</strong>
                  <br />
                  <span className="muted">
                    {shortTime(appointment.start_time)}-{shortTime(appointment.end_time)}
                  </span>
                </td>
                <td>
                  <strong>{appointment.pets?.name ?? "Тварина"}</strong>
                  <br />
                  <span className="muted">{appointment.profiles?.full_name ?? appointment.profiles?.email ?? "Власник"}</span>
                </td>
                <td>{appointment.services?.name ?? "Послуга"}</td>
                <td>{appointment.doctors?.full_name ?? "Не призначено"}</td>
                <td>
                  <span className="status">{statusLabels[appointment.status]}</span>
                </td>
                <td>
                  <div className="form-actions">
                    <Link className="button button-secondary" href={`/clinic/appointments/${appointment.id}`}>
                      Деталі
                    </Link>
                    {canManage && appointment.status === "pending" ? (
                      <form action={updateAppointmentStatus}>
                        <input type="hidden" name="id" value={appointment.id} />
                        <input type="hidden" name="status" value="confirmed" />
                        <input type="hidden" name="return_to" value="/clinic/appointments" />
                        <button className="button" type="submit">Підтвердити</button>
                      </form>
                    ) : null}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function shortTime(value: string) {
  return value.slice(0, 5);
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
