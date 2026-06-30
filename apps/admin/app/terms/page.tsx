import { PageHeader } from "../../components/page-header";

export default function TermsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Довіра" title="Умови використання" description="Beta placeholder. Review with legal specialist before public launch." />
      <section className="card">
        <h2>Beta-статус</h2>
        <p className="muted">Продукт тестується з обмеженою кількістю клінік і власників тварин. Частина функцій може змінюватися.</p>
        <h2>Медична відповідальність</h2>
        <p className="muted">Платформа не надає ветеринарні діагнози. Клініки відповідають за медичний контент, який вони створюють, а користувачі мають звертатися до ветеринарного фахівця за порадою.</p>
        <h2>Допустиме використання</h2>
        <p className="muted">Заборонено завантажувати неправдиві, незаконні або чужі дані. Обліковий запис може бути обмежено у випадку зловживань.</p>
      </section>
    </div>
  );
}
