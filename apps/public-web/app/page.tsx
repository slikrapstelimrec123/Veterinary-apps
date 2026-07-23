import Link from "next/link";

export default function Home() {
  return (
    <main className="site-shell">
      <header className="site-header">
        <Link className="brand" href="/">
          <span className="brand-mark">L</span>
          <span>
            <strong>Lappo</strong>
            <small>Турбота про тварин щодня</small>
          </span>
        </Link>
        <nav aria-label="Основна навігація">
          <Link href="/privacy">Конфіденційність</Link>
          <Link href="/terms">Умови</Link>
          <Link href="/support">Підтримка</Link>
        </nav>
      </header>

      <section className="hero">
        <p className="eyebrow">МЕДИЧНА КАРТКА ТВАРИНИ</p>
        <h1>Усе важливе про здоров’я улюбленця — поруч.</h1>
        <p className="hero-copy">
          Lappo допомагає власникам зберігати записи про прийоми,
          документи, нагадування та інформацію про своїх тварин у
          захищеному просторі.
        </p>
        <div className="hero-actions">
          <Link className="primary-link" href="/support">
            Звернутися до підтримки
          </Link>
          <Link className="secondary-link" href="/privacy">
            Як ми захищаємо дані
          </Link>
        </div>
      </section>

      <section className="feature-grid" aria-label="Можливості Lappo">
        <article>
          <span>01</span>
          <h2>Картки тварин</h2>
          <p>Основні дані, фото та важлива інформація про кожного улюбленця.</p>
        </article>
        <article>
          <span>02</span>
          <h2>Історія здоров’я</h2>
          <p>Самостійні записи про прийоми, препарати, харчування та події.</p>
        </article>
        <article>
          <span>03</span>
          <h2>Приватні документи</h2>
          <p>Файли та медичні матеріали доступні лише власнику акаунта.</p>
        </article>
      </section>

      <footer className="site-footer">
        <span>© 2026 Lappo</span>
        <div>
          <Link href="/privacy">Політика конфіденційності</Link>
          <Link href="/terms">Умови використання</Link>
          <Link href="/support">Підтримка</Link>
        </div>
      </footer>
    </main>
  );
}
