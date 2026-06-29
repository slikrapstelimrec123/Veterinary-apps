import { PageHeader } from "../../components/page-header";
import { LoginForm } from "../../components/login-form";
import { authMessage } from "../../components/auth-message";

export default function LoginPage({ searchParams }: { searchParams: { error?: string } }) {
  const message = authMessage(searchParams.error);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Access"
        title="Clinic login"
        description="Sign in with the clinic account created in Supabase Auth."
      />
      {message ? <p className="card" style={{ color: "#9f1239" }}>{message}</p> : null}
      <LoginForm />
      <p className="muted">
        New clinic? <a href="/register-clinic">Create clinic account</a>.
      </p>
    </div>
  );
}

