"use client";

import type { ReactNode } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

import { useSession } from "@/shared/auth/session";

type NavItem = {
  href: string;
  label: string;
  shortLabel: string;
};

const navItems: NavItem[] = [
  { href: "/app/home", label: "Home", shortLabel: "Home" },
  { href: "/app/schedule", label: "Cronograma", shortLabel: "Agenda" },
  { href: "/app/reminders", label: "Lembretes", shortLabel: "Lembretes" },
  { href: "/app/create", label: "Create IA", shortLabel: "Create" },
  { href: "/app/shopping", label: "Compras", shortLabel: "Compras" },
  { href: "/app/events", label: "Eventos", shortLabel: "Eventos" },
  { href: "/settings", label: "Configurações", shortLabel: "Config" },
  { href: "/notification-history", label: "Notificações", shortLabel: "Histórico" },
];

function isActive(pathname: string, href: string): boolean {
  if (href === "/") return pathname === href;
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const { user, logout } = useSession();

  return (
    <div className="min-h-screen bg-[var(--color-background)] pb-24 md:pb-0">
      <header className="sticky top-0 z-20 border-b border-[var(--color-border)] bg-[color-mix(in_oklab,var(--color-surface)_90%,white)]/90 backdrop-blur-xl">
        <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/app/home" className="inline-flex items-center gap-3">
            <span className="inline-flex h-9 w-9 items-center justify-center overflow-hidden rounded-xl border border-[var(--color-border)] bg-white">
              <Image src="/app-icon.png" alt="Organiq" width={28} height={28} className="h-7 w-7" />
            </span>
            <span className="text-lg font-semibold tracking-tight text-[var(--color-text)]">Organiq Web</span>
          </Link>

          <div className="hidden items-center gap-3 md:flex">
            <div className="rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-1 text-sm text-[var(--color-text-muted)]">
              {user?.displayName || user?.email || "Conta"}
            </div>
            <button type="button" className="oq-button oq-button-ghost" onClick={logout}>
              Sair
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto grid w-full max-w-7xl grid-cols-1 gap-6 px-4 py-6 sm:px-6 lg:grid-cols-[250px_1fr] lg:px-8">
        <aside className="hidden lg:block">
          <nav className="oq-card flex flex-col gap-1 p-2">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={isActive(pathname, item.href) ? "oq-nav-item oq-nav-item-active" : "oq-nav-item"}
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </aside>

        <main>{children}</main>
      </div>

      <nav className="fixed inset-x-3 bottom-3 z-30 grid grid-cols-4 gap-1 rounded-2xl border border-[var(--color-border)] bg-[color-mix(in_oklab,var(--color-surface)_92%,white)] p-1 shadow-[0_20px_35px_rgba(15,23,42,0.12)] backdrop-blur-xl lg:hidden">
        {navItems.slice(0, 4).map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={isActive(pathname, item.href) ? "oq-mobile-nav-item oq-mobile-nav-item-active" : "oq-mobile-nav-item"}
          >
            {item.shortLabel}
          </Link>
        ))}
      </nav>
    </div>
  );
}
