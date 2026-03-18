"use client";

import { useEffect } from "react";
import type { ReactNode } from "react";
import { useRouter } from "next/navigation";

import { useSession } from "@/shared/auth/session";
import { Spinner } from "@/shared/ui/spinner";

export default function PublicLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { bootstrap, isAuthenticated, isBootstrapping } = useSession();

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      await bootstrap();
      if (cancelled) return;
      if (isAuthenticated) {
        router.replace("/app/home");
      }
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [bootstrap, isAuthenticated, router]);

  if (isBootstrapping) {
    return (
      <main className="flex min-h-screen items-center justify-center px-6">
        <Spinner label="Preparando acesso" />
      </main>
    );
  }

  return <>{children}</>;
}
