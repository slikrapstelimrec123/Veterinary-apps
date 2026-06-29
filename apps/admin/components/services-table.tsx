import { ConfirmSubmitButton } from "./confirm-submit-button";
import { deactivateService, deleteService } from "../lib/clinic-actions";
import type { Service } from "../types";

export function ServicesTable({ services, canManage }: { services: Service[]; canManage: boolean }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>Name</th>
          <th>Category</th>
          <th>Duration</th>
          <th>Price</th>
          <th>Status</th>
          {canManage ? <th>Actions</th> : null}
        </tr>
      </thead>
      <tbody>
        {services.map((service) => (
          <tr key={service.id}>
            <td>{service.name}</td>
            <td>{service.category ?? "General"}</td>
            <td>{service.duration_minutes ?? 30} min</td>
            <td>{service.price_amount ? `${service.price_amount} ${service.price_currency ?? "UAH"}` : "Not set"}</td>
            <td><span className="status">{service.status}</span></td>
            {canManage ? (
              <td>
                <div className="form-actions">
                  <form action={deactivateService}>
                    <input name="id" type="hidden" value={service.id} />
                    <button className="button button-muted" type="submit">Deactivate</button>
                  </form>
                  <form action={deleteService}>
                    <input name="id" type="hidden" value={service.id} />
                    <ConfirmSubmitButton className="button button-danger" message="Delete this service if it is not connected to appointments?">
                      Delete
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </td>
            ) : null}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
