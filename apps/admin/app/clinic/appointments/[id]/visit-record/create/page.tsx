import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { PageHeader } from "../../../../../components/page-header";
import { StatusMessage } from "../../../../../components/status-message";
import { createVisitRecord } from "../../../../../lib/clinic-actions";
import { getVisitRecordCreateData } from "../../../../../lib/clinic-data";

export default async function CreateAppointmentVisitRecordPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { success?: string; error?: string };
}) {
  const { appointment, doctors, existingRecord } = await getVisitRecordCreateData(params.id);

  if (!appointment) {
    notFound();
  }

  if (existingRecord) {
    redirect(`/clinic/visit-records/${existingRecord.id}`);
  }

  return (
    <div className="page">
      <PageHeader
        eyebrow="Медична картка"
        title="Створити запис візиту"
        description="Додайте діагноз, нотатки про лікування, рекомендації та за потреби опублікуйте запис для власника тварини."
        action={<Link className="button button-secondary" href={`/clinic/appointments/${appointment.id}`}>Назад до запису</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        <article className="card">
          <h2>Запис</h2>
          <p>
            <strong>{formatDate(appointment.appointment_date)}</strong>
            <br />
            {shortTime(appointment.start_time)}-{shortTime(appointment.end_time)}
          </p>
          <p className="muted">Послуга: {appointment.services?.name ?? "Послуга"}</p>
        </article>
        <article className="card">
          <h2>Пацієнт</h2>
          <p><strong>{appointment.pets?.name ?? "Тварина"}</strong></p>
          <p className="muted">{appointment.profiles?.full_name ?? appointment.profiles?.email ?? "Власник"}</p>
        </article>
        <article className="card">
          <h2>Лікар</h2>
          <p>{appointment.doctors?.full_name ?? "Не призначено"}</p>
          <p className="muted">За потреби можна вибрати іншого лікаря у формі.</p>
        </article>
      </section>

      <VisitRecordForm appointmentId={appointment.id} doctors={doctors} defaultDoctorId={appointment.doctor_id ?? ""} />
    </div>
  );
}

function VisitRecordForm({ appointmentId, doctors, defaultDoctorId }: { appointmentId: string; doctors: { id: string; full_name: string }[]; defaultDoctorId: string }) {
  const today = new Date().toISOString().slice(0, 10);

  return (
    <form className="card" action={createVisitRecord}>
      <input type="hidden" name="appointment_id" value={appointmentId} />
      <div className="form-grid">
        <label className="field">
          <span>Дата візиту</span>
          <input type="date" name="visit_date" defaultValue={today} required />
        </label>
        <label className="field">
          <span>Лікар</span>
          <select name="doctor_id" defaultValue={defaultDoctorId}>
            <option value="">Не призначено</option>
            {doctors.map((doctor) => (
              <option key={doctor.id} value={doctor.id}>{doctor.full_name}</option>
            ))}
          </select>
        </label>
      </div>

      <MedicalFields />

      <div className="form-actions">
        <button className="button button-secondary" name="submit_action" value="draft" type="submit">Зберегти чернетку</button>
        <button className="button" name="submit_action" value="publish" type="submit">Опублікувати власнику</button>
        <Link className="button button-muted" href={`/clinic/appointments/${appointmentId}`}>Скасувати</Link>
      </div>
    </form>
  );
}

function MedicalFields() {
  return (
    <>
      <div className="form-grid">
        <label className="field"><span>Причина звернення</span><textarea name="reason_for_visit" /></label>
        <label className="field"><span>Симптоми</span><textarea name="symptoms" /></label>
      </div>
      <div className="form-grid">
        <label className="field"><span>Діагноз</span><textarea name="diagnosis" /></label>
        <label className="field"><span>Процедури</span><textarea name="procedures_performed" /></label>
      </div>
      <div className="form-grid">
        <label className="field"><span>Лікування</span><textarea name="treatment_notes" /></label>
        <label className="field"><span>Призначені препарати</span><textarea name="prescribed_medications" /></label>
      </div>
      <label className="field"><span>Рекомендації</span><textarea name="recommendations" /></label>
      <div className="form-grid">
        <label className="field"><span>Рекомендувати наступний візит</span><input type="checkbox" name="next_visit_recommended" /></label>
        <label className="field"><span>Дата наступного візиту</span><input type="date" name="next_visit_date" /></label>
      </div>
      <label className="field">
        <span>Внутрішні нотатки, не видимі власнику</span>
        <textarea name="internal_notes" />
      </label>
      <p className="muted">Перед публікацією потрібно заповнити діагноз, лікування або рекомендації.</p>
    </>
  );
}

function shortTime(value: string) {
  return value.slice(0, 5);
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
