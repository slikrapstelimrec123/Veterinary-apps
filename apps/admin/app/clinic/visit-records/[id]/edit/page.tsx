import Link from "next/link";
import { notFound } from "next/navigation";
import { PageHeader } from "../../../../../components/page-header";
import { StatusMessage } from "../../../../../components/status-message";
import { updateVisitRecord } from "../../../../../lib/clinic-actions";
import { getClinicVisitRecordDetails } from "../../../../../lib/clinic-data";
import type { VisitRecord } from "../../../../../types";

export default async function EditClinicVisitRecordPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { success?: string; error?: string };
}) {
  const { record } = await getClinicVisitRecordDetails(params.id);

  if (!record) {
    notFound();
  }

  return (
    <div className="page">
      <PageHeader
        eyebrow="Медична картка"
        title="Редагувати запис візиту"
        description="Оновіть медичні дані. Внутрішні нотатки залишаються прихованими від власника тварини."
        action={<Link className="button button-secondary" href={`/clinic/visit-records/${record.id}`}>Назад до деталей</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <VisitRecordEditForm record={record} />
    </div>
  );
}

function VisitRecordEditForm({ record }: { record: VisitRecord }) {
  return (
    <form className="card" action={updateVisitRecord}>
      <input type="hidden" name="id" value={record.id} />
      <div className="form-grid">
        <label className="field">
          <span>Дата візиту</span>
          <input type="date" name="visit_date" defaultValue={record.visit_date.slice(0, 10)} required />
        </label>
        <label className="field">
          <span>Поточний статус</span>
          <input value={record.status} readOnly />
        </label>
      </div>

      <div className="form-grid">
        <label className="field"><span>Причина звернення</span><textarea name="reason_for_visit" defaultValue={record.reason_for_visit ?? record.reason ?? ""} /></label>
        <label className="field"><span>Симптоми</span><textarea name="symptoms" defaultValue={record.symptoms ?? ""} /></label>
      </div>
      <div className="form-grid">
        <label className="field"><span>Діагноз</span><textarea name="diagnosis" defaultValue={record.diagnosis ?? ""} /></label>
        <label className="field"><span>Процедури</span><textarea name="procedures_performed" defaultValue={record.procedures_performed ?? ""} /></label>
      </div>
      <div className="form-grid">
        <label className="field"><span>Лікування</span><textarea name="treatment_notes" defaultValue={record.treatment_notes ?? ""} /></label>
        <label className="field"><span>Призначені препарати</span><textarea name="prescribed_medications" defaultValue={record.prescribed_medications ?? ""} /></label>
      </div>
      <label className="field"><span>Рекомендації</span><textarea name="recommendations" defaultValue={record.recommendations ?? ""} /></label>
      <div className="form-grid">
        <label className="field"><span>Рекомендувати наступний візит</span><input type="checkbox" name="next_visit_recommended" defaultChecked={record.next_visit_recommended} /></label>
        <label className="field"><span>Дата наступного візиту</span><input type="date" name="next_visit_date" defaultValue={record.next_visit_date ?? ""} /></label>
      </div>
      <label className="field"><span>Внутрішні нотатки</span><textarea name="internal_notes" defaultValue={record.internal_notes ?? ""} /></label>

      <div className="form-actions">
        <button className="button button-secondary" name="submit_action" value="draft" type="submit">Зберегти чернетку</button>
        <button className="button" name="submit_action" value="publish" type="submit">Опублікувати власнику</button>
        <button className="button button-danger" name="submit_action" value="archive" type="submit">Архівувати</button>
      </div>
    </form>
  );
}
