import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Підтримка",
  description: "Служба підтримки користувачів Lappo.",
};

export default function SupportPage() {
  return (
    <main className="legal-shell">
      <header className="site-header">
        <Link className="brand" href="/">
          <span className="brand-mark">L</span>
          <span><strong>Lappo</strong><small>Турбота про тварин щодня</small></span>
        </Link>
        <nav aria-label="Юридична навігація">
          <Link href="/privacy">Конфіденційність</Link>
          <Link href="/terms">Умови</Link>
        </nav>
      </header>
      <section className="legal-hero">
        <p className="eyebrow">МИ ПОРУЧ</p>
        <h1>Служба підтримки</h1>
        <p>
          Напишіть нам, якщо виникла проблема з акаунтом, даними,
          покупкою, оголошенням або роботою застосунку.
        </p>
      </section>
      <section className="support-grid">
        <article className="support-card">
          <h2>Зв’язатися з нами</h2>
          <p>Вкажіть email акаунта, модель телефона, версію системи та коротко опишіть проблему. Не надсилайте пароль.</p>
          <a className="support-email" href="mailto:lappo.apps@gmail.com?subject=Lappo%20—%20підтримка">
            lappo.apps@gmail.com
          </a>
        </article>
        <article className="support-card">
          <h2>Швидка перевірка</h2>
          <ol>
            <li>Переконайтеся, що встановлена остання версія Lappo.</li>
            <li>Перевірте підключення до інтернету.</li>
            <li>Закрийте й відкрийте застосунок повторно.</li>
            <li>Якщо помилка лишилась — надішліть скриншот підтримці.</li>
          </ol>
        </article>
      </section>
      <footer className="site-footer">
        <span>© 2026 Lappo</span>
        <div><Link href="/">Головна</Link><Link href="/privacy">Конфіденційність</Link><Link href="/terms">Умови</Link></div>
      </footer>
    </main>
  );
}
