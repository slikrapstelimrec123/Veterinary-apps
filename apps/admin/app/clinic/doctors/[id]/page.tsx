import { notFound } from "next/navigation";
import { DoctorForm } from "../../../../components/doctor-form";
import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { requireClinicAccess } from "../../../../lib/auth";
import { canManageClinicCatalog } from "../../../../lib/clinic-data";
import { createSupabaseServerClient } from "../../../../lib/supabase-server";
import type { Doctor } from "../../../../types";

export default async function DoctorDetailsPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { success?: string; error?: string };
}) {
  const context = await requireClinicAccess();
  const supabase = createSupabaseServerClient();
  const { data } = await supabase
    .from("doctors")
    .select("*")
    .eq("id", params.id)
    .eq("clinic_id", context.clinicId)
    .maybeSingle();

  if (!data) {
    notFound();
  }

  const doctor = data as Doctor;
  const canEdit = canManageClinicCatalog(context.clinicRole);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Профіль лікаря"
        title={doctor.full_name}
        description="Перегляд профілю та редагування даних лікаря."
        action={<a className="button button-secondary" href="/clinic/doctors">Назад до лікарів</a>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />
      <section className="card">
        <h2>{doctor.full_name}</h2>
        <p className="muted">{doctor.specialization ?? "Спеціалізацію не вказано"}</p>
        <p>{doctor.bio ?? "Біографію ще не додано."}</p>
        <span className="status">{doctor.status}</span>
      </section>
      {canEdit ? <DoctorForm doctor={doctor} /> : null}
    </div>
  );
}

