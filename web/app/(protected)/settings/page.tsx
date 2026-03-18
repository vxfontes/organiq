import Link from "next/link";

export default function SettingsPage() {
  return (
    <section className="oq-card p-8">
      <h1 className="text-2xl font-semibold tracking-tight">Configurações</h1>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">Ajuste conta, contextos e preferências de notificação.</p>

      <div className="mt-6 grid gap-3 sm:grid-cols-3">
        <Link href="/settings/account" className="rounded-2xl border border-[var(--color-border)] bg-white p-4 text-sm font-semibold">
          Conta
          <p className="mt-1 text-xs font-normal text-[var(--color-text-muted)]">Perfil e dados básicos</p>
        </Link>
        <Link href="/settings/contexts" className="rounded-2xl border border-[var(--color-border)] bg-white p-4 text-sm font-semibold">
          Contextos
          <p className="mt-1 text-xs font-normal text-[var(--color-text-muted)]">Flags e subflags</p>
        </Link>
        <Link href="/settings/notifications" className="rounded-2xl border border-[var(--color-border)] bg-white p-4 text-sm font-semibold">
          Notificações
          <p className="mt-1 text-xs font-normal text-[var(--color-text-muted)]">Preferências e digest diário</p>
        </Link>
      </div>
    </section>
  );
}
