import { createDoctor, updateDoctor } from "../lib/clinic-actions";
import type { Doctor } from "../types";

export function DoctorForm({ doctor }: { doctor?: Doctor }) {
  const action = doctor ? updateDoctor : createDoctor;

  return (
    <form action={action} className="card" style={{ display: "grid", gap: 14 }}>
      {doctor ? <input name="id" type="hidden" value={doctor.id} /> : null}
      <div className="form-grid">
        <label className="field">
          Full name
          <input name="full_name" defaultValue={doctor?.full_name ?? ""} required />
        </label>
        <label className="field">
          Specialization
          <input name="specialization" defaultValue={doctor?.specialization ?? ""} required />
        </label>
        <label className="field">
          Experience years
          <input name="experience_years" type="number" min="0" defaultValue={doctor?.experience_years ?? ""} />
        </label>
        <label className="field">
          Phone
          <input name="phone" defaultValue={doctor?.phone ?? ""} />
        </label>
        <label className="field">
          Email
          <input name="email" type="email" defaultValue={doctor?.email ?? ""} />
        </label>
        <label className="field">
          Avatar URL
          <input name="avatar_url" defaultValue={doctor?.avatar_url ?? ""} />
        </label>
        <label className="field">
          Status
          <select name="status" defaultValue={doctor?.status ?? "draft"}>
            <option value="draft">Draft</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="archived">Archived</option>
          </select>
        </label>
      </div>
      <label className="field">
        Bio
        <textarea name="bio" defaultValue={doctor?.bio ?? ""} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_public" type="checkbox" defaultChecked={doctor?.is_public ?? true} />
        Public in future clinic profile
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{doctor ? "Save doctor" : "Add doctor"}</button>
      </div>
    </form>
  );
}

