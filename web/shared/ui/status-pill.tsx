const toneByStatus: Record<string, string> = {
  PROCESSING: "oq-pill-ai",
  NEEDS_REVIEW: "oq-pill-warning",
  DONE: "oq-pill-success",
  CONFIRMED: "oq-pill-success",
  ERROR: "oq-pill-danger",
  OVERDUE: "oq-pill-danger",
};

export function StatusPill({ status }: { status: string }) {
  const normalized = status.trim().toUpperCase();
  const toneClass = toneByStatus[normalized] ?? "oq-pill-default";
  return <span className={`oq-pill ${toneClass}`}>{normalized}</span>;
}
