import Link from "next/link";
import type { Doctor } from "../types";

export function DoctorCard({ doctor }: { doctor: Doctor }) {
  return (
    <article className="card">
      <h2>{doctor.full_name}</h2>
      <p className="muted">{doctor.specialization ?? "Specialization not set"}</p>
      <p>{doctor.bio ?? "No bio yet."}</p>
      <div className="form-actions">
        <span className="status">{doctor.status}</span>
        <Link className="button button-secondary" href={`/clinic/doctors/${doctor.id}`}>Open profile</Link>
      </div>
    </article>
  );
}

