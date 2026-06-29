export function StatCard({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <section className="card">
      <p className="eyebrow">{label}</p>
      <h2>{value}</h2>
      <p className="muted">{note}</p>
    </section>
  );
}

