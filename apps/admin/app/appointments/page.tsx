import { PageHeader } from "../../components/page-header";
import { appointments } from "../../lib/placeholder-data";

export default function AppointmentsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Calendar" title="Appointments" description="Clinic booking list for receptionists and doctors." action={<button className="button">Create manually</button>} />
      <table className="table">
        <thead>
          <tr><th>Date and time</th><th>Client</th><th>Pet</th><th>Status</th></tr>
        </thead>
        <tbody>
          {appointments.map((appointment) => (
            <tr key={appointment.id}>
              <td>{appointment.startsAt}</td>
              <td>{appointment.ownerName}</td>
              <td>{appointment.petId}</td>
              <td><span className="status">{appointment.status}</span></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

