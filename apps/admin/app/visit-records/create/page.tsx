import { PageHeader } from "../../../components/page-header";

export default function CreateVisitRecordPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Медичний запис" title="Створити запис візиту" description="Чернеткова форма для діагнозу, нотаток про лікування, рекомендацій та внутрішніх нотаток." action={<button className="button">Зберегти чернетку</button>} />
      <form className="card" style={{ display: "grid", gap: 12 }}>
        <label>Діагноз<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Нотатки про лікування<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Рекомендації<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
        <label>Внутрішні нотатки<textarea style={{ width: "100%", minHeight: 90, marginTop: 6 }} /></label>
      </form>
    </div>
  );
}

