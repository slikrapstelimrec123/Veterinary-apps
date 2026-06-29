import { PageHeader } from "../../components/page-header";
import { pets } from "../../lib/placeholder-data";

export default function PetsPage() {
  return (
    <div className="page">
      <PageHeader eyebrow="Medical cards" title="Pets" description="Pet cards connected to this clinic through appointments or visits." />
      <section className="grid">
        {pets.map((pet) => (
          <div className="card" key={pet.id}>
            <h2>{pet.name}</h2>
            <p className="muted">{pet.species} • {pet.breed}</p>
          </div>
        ))}
      </section>
    </div>
  );
}

