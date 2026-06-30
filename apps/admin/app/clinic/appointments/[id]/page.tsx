import Link from "next/link";
import { notFound } from "next/navigation";
import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { assignAppointmentDoctor, updateAppointmentStatus } from "../../../../lib/clinic-actions";
import { canManageClinicAppointments, getClinicAppointmentDetails } from "../../../../lib/clinic-data";
import type { Appointment, Doctor } from "../../../../types";

const statusLabels: Record<Appointment["status"], string> = {
  pending: "Очікує",
  confirmed: "Підтверджено",
  completed: "Завершено",
  cancelled_by_owner: "Скасовано власником",
  cancelled_by_clinic: "Скасовано клінікою",
  no_show: "Не прийшли",
};

export default async function ClinicAppointmentDetailsPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { success?: string; error?: string };
}) {
  const { context, appointment, doctors, visitRecord } = await getClinicAppointmentDetails(params.id);

  if (!appointment) {
    notFound();
  }

  const canManage = canManageClinicAppointments(context.clinicRole);
  const returnTo = `/clinic/appointments/${appointment.id}`;

  return (
    <div className="page">
      <PageHeader
        eyebrow="Запис"
        title={`${appointment.pets?.name ?? "Тварина"} - ${appointment.services?.name ?? "Послуга"}`}
        description="Деталі бронювання, статус, нотатки власника та базове керування для адміністратора клініки."
        action={<Link className="button button-secondary" href="/clinic/appointments">Назад до записів</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        <article className="card">
          <h2>Візит</h2>
          <p>
            <strong>{formatDate(appointment.appointment_date)}</strong>
            <br />
            {shortTime(appointment.start_time)}-{shortTime(appointment.end_time)}
          </p>
          <p className="muted">Статус</p>
          <span className="status">{statusLabels[appointment.status]}</span>
        </article>
        <article className="card">
          <h2>Клієнт і тварина</h2>
          <p>
            <strong>{appointment.profiles?.full_name ?? "Власник"}</strong>
            <br />
            <span className="muted">{appointment.profiles?.email ?? ""}</span>
          </p>
          <p>
            {appointment.pets?.name ?? "Тварина"}
            {appointment.pets?.breed ? `, ${appointment.pets.breed}` : ""}
          </p>
        </article>
        <article className="card">
          <h2>Послуга</h2>
          <p>{appointment.services?.name ?? "Послуга"}</p>
          <p className="muted">Лікар: {appointment.doctors?.full_name ?? "Не призначено"}</p>
        </article>
      </section>

      <section className="card">
        <h2>Нотатки</h2>
        <p className="muted">Власник</p>
        <p>{appointment.owner_note ?? "Нотаток від власника немає."}</p>
        <p className="muted">Клініка</p>
        <p>{appointment.clinic_note ?? "Нотатку клініки ще не додано."}</p>
        {appointment.cancellation_reason ? (
          <>
            <p className="muted">Причина скасування</p>
            <p>{appointment.cancellation_reason}</p>
          </>
        ) : null}
      </section>

      {canManage ? (
        <section className="grid">
          <AppointmentStatusForm appointment={appointment} returnTo={returnTo} />
          <AssignDoctorForm appointment={appointment} doctors={doctors} returnTo={returnTo} />
        </section>
      ) : (
        <section className="card">
          <h2>Режим перегляду</h2>
          <p className="muted">Ветеринар може переглядати призначений запис, але зміну статусу виконує власник або менеджер клініки.</p>
        </section>
      )}

      <section className="card">
        <h2>Медична картка</h2>
        <p className="muted">Медичний запис містить діагноз, лікування, рекомендації та приватні документи.</p>
        {visitRecord ? (
          <Link className="button" href={`/clinic/visit-records/${visitRecord.id}`}>Переглянути медичний запис</Link>
        ) : (
          <Link className="button" href={`/clinic/appointments/${appointment.id}/visit-record/create`}>Створити запис в медкартці</Link>
        )}
      </section>
    </div>
  );
}

function AppointmentStatusForm({ appointment, returnTo }: { appointment: Appointment; returnTo: string }) {
  return (
    <form className="card" action={updateAppointmentStatus}>
      <h2>Змінити статус</h2>
      <input type="hidden" name="id" value={appointment.id} />
      <input type="hidden" name="return_to" value={returnTo} />
      <label className="field">
        <span>Статус</span>
        <select name="status" defaultValue={appointment.status}>
          <option value="pending">Очікує</option>
          <option value="confirmed">Підтверджено</option>
          <option value="completed">Завершено</option>
          <option value="cancelled_by_clinic">Скасовано клінікою</option>
          <option value="no_show">Не прийшли</option>
        </select>
      </label>
      <label className="field">
        <span>Нотатка клініки</span>
        <textarea name="clinic_note" defaultValue={appointment.clinic_note ?? ""} />
      </label>
      <label className="field">
        <span>Причина скасування</span>
        <input name="cancellation_reason" defaultValue={appointment.cancellation_reason ?? ""} />
      </label>
      <button className="button" type="submit">Зберегти</button>
    </form>
  );
}

function AssignDoctorForm({ appointment, doctors, returnTo }: { appointment: Appointment; doctors: Doctor[]; returnTo: string }) {
  return (
    <form className="card" action={assignAppointmentDoctor}>
      <h2>Призначити лікаря</h2>
      <input type="hidden" name="id" value={appointment.id} />
      <input type="hidden" name="return_to" value={returnTo} />
      <label className="field">
        <span>Лікар</span>
        <select name="doctor_id" defaultValue={appointment.doctor_id ?? ""}>
          <option value="">Не призначено</option>
          {doctors.map((doctor) => (
            <option key={doctor.id} value={doctor.id}>{doctor.full_name}</option>
          ))}
        </select>
      </label>
      <button className="button" type="submit">Зберегти лікаря</button>
    </form>
  );
}

function shortTime(value: string) {
  return value.slice(0, 5);
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
