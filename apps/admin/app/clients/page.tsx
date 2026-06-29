import { PageHeader } from "../../components/page-header";

export default function ClientsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="CRM light" title="Clients" description="Clients connected to appointments and pet records." />
      <table className="table">
        <thead>
          <tr><th>Name</th><th>Phone</th><th>Pets</th></tr>
        </thead>
        <tbody>
          <tr><td>Olena Petrenko</td><td>+380 00 000 0000</td><td>Luna</td></tr>
          <tr><td>Dmytro Horbunov</td><td>+380 00 000 0000</td><td>Milo</td></tr>
        </tbody>
      </table>
    </div>
  );
}

