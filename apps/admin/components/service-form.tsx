import { createService, updateService } from "../lib/clinic-actions";
import type { Service } from "../types";

export function ServiceForm({ service }: { service?: Service }) {
  const action = service ? updateService : createService;

  return (
    <form action={action} className="card" style={{ display: "grid", gap: 14 }}>
      {service ? <input name="id" type="hidden" value={service.id} /> : null}
      <div className="form-grid">
        <label className="field">
          Service name
          <input name="name" defaultValue={service?.name ?? ""} required />
        </label>
        <label className="field">
          Category
          <input name="category" defaultValue={service?.category ?? ""} />
        </label>
        <label className="field">
          Price
          <input name="price_amount" type="number" min="0" step="0.01" defaultValue={service?.price_amount ?? ""} />
        </label>
        <label className="field">
          Duration minutes
          <input name="duration_minutes" type="number" min="1" defaultValue={service?.duration_minutes ?? 30} />
        </label>
        <label className="field">
          Status
          <select name="status" defaultValue={service?.status ?? "inactive"}>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="archived">Archived</option>
          </select>
        </label>
      </div>
      <label className="field">
        Description
        <textarea name="description" defaultValue={service?.description ?? ""} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_public" type="checkbox" defaultChecked={service?.is_public ?? true} />
        Public in future clinic profile
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{service ? "Save service" : "Add service"}</button>
      </div>
    </form>
  );
}

