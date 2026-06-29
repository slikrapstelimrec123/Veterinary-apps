export function ProfileCompletionChecklist({
  items,
  percent,
}: {
  items: Array<{ label: string; done: boolean }>;
  percent: number;
}) {
  return (
    <section className="card">
      <h2>Заповненість профілю</h2>
      <p className="muted">{percent}% готово до публікації</p>
      <ul className="checklist">
        {items.map((item) => (
          <li key={item.label}>
            <span>{item.label}</span>
            <span className="status">{item.done ? "Готово" : "Далі"}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}

