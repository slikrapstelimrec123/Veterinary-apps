export function ProfileCompletionChecklist({
  items,
  percent,
}: {
  items: Array<{ label: string; done: boolean }>;
  percent: number;
}) {
  return (
    <section className="card">
      <h2>Profile completion</h2>
      <p className="muted">{percent}% ready for publishing</p>
      <ul className="checklist">
        {items.map((item) => (
          <li key={item.label}>
            <span>{item.label}</span>
            <span className="status">{item.done ? "Done" : "Next"}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}

