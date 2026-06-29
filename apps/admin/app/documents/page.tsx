import { PageHeader } from "../../components/page-header";

export default function DocumentsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Файли" title="Документи" description="Приватні медичні файли, прикріплені до завершених або чернеткових записів візитів." action={<button className="button">Завантажити документ</button>} />
      <section className="grid">
        <div className="card">
          <h2>Сертифікат про вакцинацію</h2>
          <p className="muted">Приватний файл. Підписані URL-адреси генеруються лише після перевірки доступу.</p>
        </div>
        <div className="card">
          <h2>Фото результату аналізу</h2>
          <p className="muted">Пов'язано з профілактичним оглядом Луни.</p>
        </div>
      </section>
    </div>
  );
}

