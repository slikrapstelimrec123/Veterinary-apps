import { PageHeader } from "../../components/page-header";
import { LoginForm } from "../../components/login-form";
import { authMessage } from "../../components/auth-message";

export default function LoginPage({ searchParams }: { searchParams: { error?: string } }) {
  const message = authMessage(searchParams.error);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Доступ"
        title="Вхід до клініки"
        description="Увійдіть за допомогою облікового запису клініки, створеного в Supabase Auth."
      />
      {message ? <p className="card" style={{ color: "#9f1239" }}>{message}</p> : null}
      <LoginForm />
      <p className="muted">
        Нова клініка? <a href="/register-clinic">Створити обліковий запис клініки</a>.
      </p>
    </div>
  );
}

