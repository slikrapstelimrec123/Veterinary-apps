import { PageHeader } from "../../components/page-header";

export default function ClientsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="CRM" title="Клієнти" description="Клієнти, пов'язані із записами та медичними картками тварин." />
      <table className="table">
        <thead>
          <tr><th>Ім'я</th><th>Телефон</th><th>Тварини</th></tr>
        </thead>
        <tbody>
          <tr><td>Olena Petrenko</td><td>+380 00 000 0000</td><td>Luna</td></tr>
          <tr><td>Dmytro Horbunov</td><td>+380 00 000 0000</td><td>Milo</td></tr>
        </tbody>
      </table>
    </div>
  );
}

