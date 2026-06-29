import { updateClinicProfile } from "../lib/clinic-actions";
import type { Clinic } from "../types";

export function ClinicProfileForm({ clinic, canEdit }: { clinic: Clinic; canEdit: boolean }) {
  return (
    <form action={updateClinicProfile} className="card" style={{ display: "grid", gap: 16 }}>
      <div className="form-grid">
        <label className="field">
          Clinic name
          <input name="name" defaultValue={clinic.name} required disabled={!canEdit} />
        </label>
        <label className="field">
          City
          <input name="city" defaultValue={clinic.city ?? ""} required disabled={!canEdit} />
        </label>
        <label className="field">
          Country
          <input name="country" defaultValue={clinic.country ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Address
          <input name="address" defaultValue={clinic.address ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Phone
          <input name="phone" defaultValue={clinic.phone ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Email
          <input name="email" defaultValue={clinic.email ?? ""} type="email" disabled={!canEdit} />
        </label>
        <label className="field">
          Website
          <input name="website" defaultValue={clinic.website ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Logo URL
          <input name="logo_url" defaultValue={clinic.logo_url ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Cover image URL
          <input name="cover_image_url" defaultValue={clinic.cover_image_url ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Status
          <select name="status" defaultValue={clinic.status} disabled={!canEdit}>
            <option value="draft">Draft</option>
            <option value="pending_verification">Pending verification</option>
            <option value="published">Published</option>
          </select>
        </label>
      </div>
      <label className="field">
        Description
        <textarea name="description" defaultValue={clinic.description ?? ""} disabled={!canEdit} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="published" type="checkbox" defaultChecked={clinic.published} disabled={!canEdit} />
        Published for future pet owner discovery
      </label>
      <div className="form-actions">
        <button className="button" type="submit" disabled={!canEdit}>Save changes</button>
        {!canEdit ? <span className="muted">You can view this profile, but cannot edit it.</span> : null}
      </div>
    </form>
  );
}
