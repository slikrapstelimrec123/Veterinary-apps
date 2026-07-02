import { joinPetOwnerWaitlist } from "../lib/waitlist-actions";

type SearchParams = {
  success?: string;
  error?: string;
};

export default function LandingPage({ searchParams }: { searchParams: SearchParams }) {
  const joined = searchParams.success === "waitlist_joined";
  const hasError = Boolean(searchParams.error);

  return (
    <div className="page">
      <section className="landing-hero">
        <div>
          <p className="eyebrow">VetCare для власників тварин</p>
          <h1>Цифровий паспорт тварини у вашому телефоні</h1>
          <p className="landing-lead">
            Зберігайте дані про тварину, вакцинації, профілактику, документи, нагадування та безпечну QR-картку для
            нашийника в одному спокійному місці.
          </p>
          <div className="form-actions">
            <a className="button" href="#waitlist">Приєднатися до beta</a>
            <a className="button button-secondary" href="/login">Увійти до кабінету клініки</a>
          </div>
        </div>
      </section>

      <section className="grid">
        {[
          ["Паспорт", "Профіль тварини, мікрочип, контакти власника, алергії та особливі нотатки."],
          ["Профілактика", "Вакцинації, обробки від кліщів, дегельмінтизація та наступні дати."],
          ["Документи", "Скани паспорта, довідки, рецепти та результати аналізів."],
          ["QR / PDF", "Публічна мінікартка з безпечними даними та PDF-зведення для поїздок."],
        ].map(([title, text]) => (
          <article className="card" key={title}>
            <h2>{title}</h2>
            <p className="muted">{text}</p>
          </article>
        ))}
      </section>

      <section className="card" id="waitlist">
        <p className="eyebrow">Beta для власників</p>
        <h2>Отримати ранній доступ</h2>
        <p className="muted">
          Ми збираємо першу групу власників тварин для тестування цифрового паспорта. Клінічний кабінет залишається
          пілотним B2B-модулем.
        </p>
        {joined && <p className="notice notice-success">Дякуємо. Ви у списку очікування.</p>}
        {hasError && <p className="notice notice-error">Не вдалося зберегти заявку. Перевірте email і згоду.</p>}
        <form action={joinPetOwnerWaitlist} className="form-grid">
          <label className="field">
            Email *
            <input name="email" type="email" required placeholder="you@example.com" />
          </label>
          <label className="field">
            Імʼя
            <input name="name" placeholder="Олена" />
          </label>
          <label className="field">
            Телефон
            <input name="phone" placeholder="+380..." />
          </label>
          <label className="field">
            Тварина
            <select name="pet_type" defaultValue="">
              <option value="">Оберіть</option>
              <option value="dog">Собака</option>
              <option value="cat">Кіт</option>
              <option value="other">Інша тварина</option>
            </select>
          </label>
          <label className="field landing-consent">
            <span>
              <input name="consent" type="checkbox" required /> Я погоджуюся на обробку заявки для beta-доступу.
            </span>
          </label>
          <div className="form-actions">
            <button className="button" type="submit">Надіслати заявку</button>
          </div>
        </form>
      </section>
    </div>
  );
}
