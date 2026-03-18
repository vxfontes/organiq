export function FeaturePlaceholder({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <section className="oq-card min-h-[240px] p-8">
      <h1 className="text-2xl font-semibold tracking-tight text-[var(--color-text)]">{title}</h1>
      <p className="mt-3 max-w-[64ch] text-sm leading-6 text-[var(--color-text-muted)]">{description}</p>
      <div className="mt-8 grid gap-3 sm:grid-cols-3">
        <div className="h-24 rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)]" />
        <div className="h-24 rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)]" />
        <div className="h-24 rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)]" />
      </div>
    </section>
  );
}
