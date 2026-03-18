"use client";

import { useSession } from "@/shared/auth/session";

export default function SettingsAccountPage() {
  const { user } = useSession();

  return (
    <section className="oq-card p-8">
      <h1 className="text-2xl font-semibold tracking-tight">Conta</h1>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">Dados do usuário autenticado via `/v1/me`.</p>

      <dl className="mt-6 grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
          <dt className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">Nome</dt>
          <dd className="mt-1 text-sm font-semibold">{user?.displayName || "-"}</dd>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
          <dt className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">Email</dt>
          <dd className="mt-1 text-sm font-semibold">{user?.email || "-"}</dd>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
          <dt className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">Locale</dt>
          <dd className="mt-1 text-sm font-semibold">{user?.locale || "-"}</dd>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
          <dt className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">Timezone</dt>
          <dd className="mt-1 text-sm font-semibold">{user?.timezone || "-"}</dd>
        </div>
      </dl>
    </section>
  );
}
