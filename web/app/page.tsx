"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

import { useSession } from "@/shared/auth/session";
import { Spinner } from "@/shared/ui/spinner";

export default function SplashPage() {
  const router = useRouter();
  const { bootstrap, isBootstrapping, error, clearError } = useSession();

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      const hasSession = await bootstrap();
      if (cancelled) return;
      router.replace(hasSession ? "/app/home" : "/auth");
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [bootstrap, router]);

  return (
    <main className="flex min-h-screen items-center justify-center px-6">
      <section className="oq-card w-full max-w-md p-8 text-center">
        <Image src="/app-icon.png" alt="Organiq" width={80} height={80} className="mx-auto h-20 w-20" />
        <h1 className="mt-5 text-2xl font-semibold tracking-tight">Organiq Web</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">Conectando com seu espaço de organização...</p>

        <div className="mt-6 flex justify-center">
          <Spinner label={isBootstrapping ? "Verificando sessão" : "Redirecionando"} />
        </div>

        {error ? (
          <div className="mt-6 rounded-xl border border-[var(--color-danger-600)]/25 bg-[color-mix(in_oklab,var(--color-danger-600)_12%,white)] p-3 text-sm text-[var(--color-danger-600)]">
            <p>{error}</p>
            <button type="button" className="mt-3 oq-button oq-button-ghost" onClick={() => {
              clearError();
              void bootstrap(true);
            }}>
              Tentar novamente
            </button>
          </div>
        ) : null}
      </section>
    </main>
  );
}
