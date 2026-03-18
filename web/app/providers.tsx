"use client";

import type { ReactNode } from "react";

import { SessionProvider } from "@/shared/auth/session";

export function AppProviders({ children }: { children: ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
