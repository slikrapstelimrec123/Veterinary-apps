import { PageHeader } from "../../components/page-header";

export default function ForgotPasswordPage() {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Відновлення"
        title="Забули пароль"
        description="Відправлення листа для скидання пароля буде підключено після перевірки основної автентифікації."
      />
      <section className="card">
        <p className="muted">Заготовка для відновлення пароля через Supabase.</p>
      </section>
    </div>
  );
}

