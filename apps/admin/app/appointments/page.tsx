import { PageHeader } from "../../components/page-header";
import { appointments } from "../../lib/placeholder-data";

export default function AppointmentsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Календар" title="Записи" description="Список бронювань клініки для реєстраторів та лікарів." action={<button className="button">Створити вручну</button>} />
      <table className="table">
        <thead>
          <tr><th>Дата і час</th><th>Клієнт</th><th>Тварина</th><th>Статус</th></tr>
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

