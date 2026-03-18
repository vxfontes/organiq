export function Spinner({ label }: { label?: string }) {
  return (
    <div className="inline-flex items-center gap-2 text-sm text-[var(--color-text-muted)]" role="status">
      <span className="oq-spinner" aria-hidden="true" />
      {label ? <span>{label}</span> : null}
    </div>
  );
}
