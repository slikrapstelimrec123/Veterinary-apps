export function LoadingState({ label = "Завантаження..." }: { label?: string }) {
  return <div className="card muted">{label}</div>;
}

