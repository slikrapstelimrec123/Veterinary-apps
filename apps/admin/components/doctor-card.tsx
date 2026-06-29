import Link from "next/link";
import type { Doctor } from "../types";

export function DoctorCard({ doctor }: { doctor: Doctor }) {
  return (
    <article className="card">
      <h2>{doctor.full_name}</h2>
      <p className="muted">{doctor.specialization ?? "Спеціалізацію не вказано"}</p>
      <p>{doctor.bio ?? "Біографію ще не додано."}</p>
      <div className="form-actions">
        <span className="status">{doctor.status}</span>
        <Link className="button button-secondary" href={`/clinic/doctors/${doctor.id}`}>Відкрити профіль</Link>
      </div>
    </article>
  );
}

