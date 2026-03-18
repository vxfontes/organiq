import Link from "next/link";

export default function AuthLandingPage() {
  return (
    <main className="min-h-screen px-6 py-10">
      <div className="mx-auto grid w-full max-w-6xl gap-8 lg:grid-cols-[1.1fr_0.9fr]">
        <section className="oq-card relative overflow-hidden p-8 sm:p-10">
          <div className="pointer-events-none absolute -left-14 -top-20 h-52 w-52 rounded-full bg-[color-mix(in_oklab,var(--color-primary-200)_70%,transparent)] blur-2xl" />
          <div className="pointer-events-none absolute -bottom-20 -right-14 h-56 w-56 rounded-full bg-[color-mix(in_oklab,var(--color-ai-100)_80%,transparent)] blur-2xl" />

          <div className="relative">
            <div className="inline-flex rounded-full border border-[var(--color-border)] bg-white px-3 py-1 text-xs font-semibold tracking-wide text-[var(--color-text-muted)]">
              ORGANIZAÇÃO PESSOAL + IA
            </div>
            <h1 className="mt-5 max-w-[20ch] text-4xl font-semibold leading-tight tracking-tight">
              Sua rotina mais leve e inteligente
            </h1>
            <p className="mt-4 max-w-[48ch] text-base leading-7 text-[var(--color-text-muted)]">
              Concentre tarefas, lembretes, listas de compras e agenda em um fluxo único. O Organiq transforma entradas rápidas em ações reais.
            </p>

            <div className="mt-8 grid gap-3 sm:grid-cols-3">
              <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
                <p className="text-sm font-semibold">Quick Add</p>
                <p className="mt-1 text-xs text-[var(--color-text-muted)]">Texto livre para ações instantâneas</p>
              </div>
              <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
                <p className="text-sm font-semibold">Home Viva</p>
                <p className="mt-1 text-xs text-[var(--color-text-muted)]">Timeline diária com prioridade real</p>
              </div>
              <div className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
                <p className="text-sm font-semibold">Contextos</p>
                <p className="mt-1 text-xs text-[var(--color-text-muted)]">Flags e subflags para organizar sua vida</p>
              </div>
            </div>
          </div>
        </section>

        <section className="oq-card flex flex-col justify-center p-8 sm:p-10">
          <h2 className="text-2xl font-semibold tracking-tight">Começar agora</h2>
          <p className="mt-2 text-sm text-[var(--color-text-muted)]">Entre na sua conta ou crie uma em poucos segundos.</p>

          <div className="mt-8 space-y-3">
            <Link href="/auth/signup" className="oq-button oq-button-primary flex w-full items-center justify-center">
              Criar conta
            </Link>
            <Link href="/auth/login" className="oq-button oq-button-ghost flex w-full items-center justify-center">
              Já tenho conta
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
