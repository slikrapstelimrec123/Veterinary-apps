import Link from "next/link";
import { notFound } from "next/navigation";
import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { uploadVisitDocument } from "../../../../lib/clinic-actions";
import { getClinicVisitRecordDetails } from "../../../../lib/clinic-data";
import type { VisitDocument, VisitRecord } from "../../../../types";

const statusLabels: Record<VisitRecord["status"], string> = {
  draft: "Чернетка",
  published: "Опубліковано",
  archived: "Архів",
};

export default async function ClinicVisitRecordDetailsPage({
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

  const documents = record.visit_documents ?? [];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Медична картка"
        title={`${record.pets?.name ?? "Тварина"} - ${record.diagnosis ?? record.reason_for_visit ?? "Запис візиту"}`}
        description="Деталі медичного запису, приватні документи та видимість для власника тварини."
        action={<Link className="button button-secondary" href="/clinic/visit-records">Назад до історії</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        <article className="card">
          <h2>Статус</h2>
          <p><span className="status">{statusLabels[record.status]}</span></p>
          <p className="muted">Власник бачить запис тільки після публікації.</p>
        </article>
        <article className="card">
          <h2>Пацієнт</h2>
          <p><strong>{record.pets?.name ?? "Тварина"}</strong></p>
          <p className="muted">{record.profiles?.full_name ?? record.profiles?.email ?? "Власник"}</p>
        </article>
        <article className="card">
          <h2>Візит</h2>
          <p>{formatDate(record.visit_date)}</p>
          <p className="muted">Лікар: {record.doctors?.full_name ?? "Не призначено"}</p>
        </article>
      </section>

      <section className="grid">
        <RecordCard title="Причина звернення" body={record.reason_for_visit ?? record.reason ?? "Не вказано"} />
        <RecordCard title="Симптоми" body={record.symptoms ?? "Не вказано"} />
        <RecordCard title="Діагноз" body={record.diagnosis ?? "Не вказано"} />
        <RecordCard title="Процедури" body={record.procedures_performed ?? "Не вказано"} />
        <RecordCard title="Лікування" body={record.treatment_notes ?? "Не вказано"} />
        <RecordCard title="Препарати" body={record.prescribed_medications ?? "Не вказано"} />
        <RecordCard title="Рекомендації" body={record.recommendations ?? "Не вказано"} />
        <RecordCard title="Наступний візит" body={record.next_visit_recommended ? record.next_visit_date ?? "Дата не вказана" : "Не рекомендовано"} />
      </section>

      <section className="card">
        <h2>Внутрішні нотатки</h2>
        <p>{record.internal_notes ?? "Внутрішніх нотаток немає."}</p>
        <p className="muted">Цей блок не відображається у мобільному застосунку власника тварини.</p>
      </section>

      <section className="grid">
        <article className="card">
          <h2>Документи</h2>
          {documents.length === 0 ? (
            <p className="muted">Документи ще не додані.</p>
          ) : (
            <div style={{ display: "grid", gap: 10 }}>
              {documents.map((document) => (
                <DocumentRow key={document.id} document={document} />
              ))}
            </div>
          )}
        </article>
        <UploadDocumentForm visitRecordId={record.id} />
      </section>

      <div className="form-actions">
        <Link className="button" href={`/clinic/visit-records/${record.id}/edit`}>Редагувати</Link>
        {record.appointment_id ? <Link className="button button-secondary" href={`/clinic/appointments/${record.appointment_id}`}>Запис</Link> : null}
      </div>
    </div>
  );
}

function RecordCard({ title, body }: { title: string; body: string }) {
  return (
    <article className="card">
      <h2>{title}</h2>
      <p>{body}</p>
    </article>
  );
}

function DocumentRow({ document }: { document: VisitDocument }) {
  return (
    <div style={{ borderBottom: "1px solid var(--border)", paddingBottom: 10 }}>
      <strong>{document.title ?? document.file_name ?? "Документ"}</strong>
      <p className="muted">
        {document.document_type} · {document.file_type ?? "файл"} · {document.is_visible_to_owner ? "видимий власнику" : "лише клініка"}
      </p>
      {document.description ? <p>{document.description}</p> : null}
    </div>
  );
}

function UploadDocumentForm({ visitRecordId }: { visitRecordId: string }) {
  return (
    <form className="card" action={uploadVisitDocument} encType="multipart/form-data">
      <h2>Завантажити документ</h2>
      <input type="hidden" name="visit_record_id" value={visitRecordId} />
      <label className="field"><span>Файл PDF/JPG/PNG/HEIC до 10 MB</span><input type="file" name="file" required /></label>
      <label className="field"><span>Назва</span><input name="title" /></label>
      <label className="field">
        <span>Тип документа</span>
        <select name="document_type" defaultValue="other">
          <option value="lab_result">Результат аналізу</option>
          <option value="certificate">Сертифікат</option>
          <option value="prescription">Рецепт</option>
          <option value="xray">Рентген</option>
          <option value="ultrasound">УЗД</option>
          <option value="photo">Фото</option>
          <option value="vaccination_record">Вакцинація</option>
          <option value="other">Інше</option>
        </select>
      </label>
      <label className="field"><span>Опис</span><textarea name="description" /></label>
      <label className="field"><span>Видимий власнику</span><input type="checkbox" name="is_visible_to_owner" defaultChecked /></label>
      <button className="button" type="submit">Завантажити приватно</button>
    </form>
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
