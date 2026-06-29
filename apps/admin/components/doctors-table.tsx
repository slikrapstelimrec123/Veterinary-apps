import { ConfirmSubmitButton } from "./confirm-submit-button";
import { deactivateDoctor, deleteDoctor } from "../lib/clinic-actions";
import type { Doctor } from "../types";

export function DoctorsTable({ doctors, canManage }: { doctors: Doctor[]; canManage: boolean }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>Name</th>
          <th>Specialization</th>
          <th>Contact</th>
          <th>Status</th>
          {canManage ? <th>Actions</th> : null}
        </tr>
      </thead>
      <tbody>
        {doctors.map((doctor) => (
          <tr key={doctor.id}>
            <td>{doctor.full_name}</td>
            <td>{doctor.specialization ?? "Not set"}</td>
            <td>{doctor.email ?? doctor.phone ?? "Not set"}</td>
            <td><span className="status">{doctor.status}</span></td>
            {canManage ? (
              <td>
                <div className="form-actions">
                  <a className="button button-secondary" href={`/clinic/doctors/${doctor.id}`}>Edit</a>
                  <form action={deactivateDoctor}>
                    <input name="id" type="hidden" value={doctor.id} />
                    <button className="button button-muted" type="submit">Deactivate</button>
                  </form>
                  <form action={deleteDoctor}>
                    <input name="id" type="hidden" value={doctor.id} />
                    <ConfirmSubmitButton className="button button-danger" message="Delete this doctor if it is not connected to appointments?">
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
