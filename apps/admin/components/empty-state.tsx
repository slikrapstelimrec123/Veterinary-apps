export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: React.ReactNode;
}) {
  return (
    <section className="card empty-state">
      <h2>{title}</h2>
      <p className="muted">{description}</p>
      {action ? <div style={{ marginTop: 14 }}>{action}</div> : null}
    </section>
  );
}

