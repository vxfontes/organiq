"use client";

import { useEffect } from "react";
import type { ReactNode } from "react";
import { useRouter } from "next/navigation";

import { useSession } from "@/shared/auth/session";
import { AppShell } from "@/shared/ui/shell";
import { Spinner } from "@/shared/ui/spinner";

export default function ProtectedLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { bootstrap, isBootstrapping, isAuthenticated, isBootstrapped } = useSession();

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      const ok = await bootstrap();
      if (cancelled) return;
      if (!ok) {
        router.replace("/auth");
      }
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [bootstrap, router]);

  if (!isBootstrapped || isBootstrapping) {
    return (
      <main className="flex min-h-screen items-center justify-center px-6">
        <Spinner label="Carregando workspace" />
      </main>
    );
  }

  if (!isAuthenticated) {
    return (
      <main className="flex min-h-screen items-center justify-center px-6">
        <Spinner label="Redirecionando para autenticação" />
      </main>
    );
  }

  return <AppShell>{children}</AppShell>;
}
