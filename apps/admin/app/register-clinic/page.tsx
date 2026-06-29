import { PageHeader } from "../../components/page-header";
import { RegisterClinicForm } from "../../components/register-clinic-form";

export default function RegisterClinicPage() {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Clinic registration"
        title="Create clinic workspace"
        description="Creates a clinic owner profile, draft clinic, and active clinic membership."
      />
      <RegisterClinicForm />
    </div>
  );
}

