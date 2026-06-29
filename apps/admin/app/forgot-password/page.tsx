import { PageHeader } from "../../components/page-header";

export default function ForgotPasswordPage() {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Recovery"
        title="Forgot password"
        description="Password reset email flow will be connected after core auth is verified."
      />
      <section className="card">
        <p className="muted">Placeholder for Supabase password recovery.</p>
      </section>
    </div>
  );
}

