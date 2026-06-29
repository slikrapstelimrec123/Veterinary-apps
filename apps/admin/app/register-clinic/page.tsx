import { PageHeader } from "../../components/page-header";
import { RegisterClinicForm } from "../../components/register-clinic-form";

export default function RegisterClinicPage() {
  return (
    <div className="page">
      <PageHeader
        eyebrow="Реєстрація клініки"
        title="Створити робочий простір клініки"
        description="Створює профіль власника клініки, чернеткову клініку та активне членство в клініці."
      />
      <RegisterClinicForm />
    </div>
  );
}

