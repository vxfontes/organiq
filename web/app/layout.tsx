import type { Metadata } from "next";
import localFont from "next/font/local";
import type { ReactNode } from "react";

import { AppProviders } from "@/app/providers";

import "./globals.css";

const manrope = localFont({
  variable: "--font-manrope",
  display: "swap",
  src: [
    { path: "./fonts/Manrope-ExtraLight.ttf", weight: "200", style: "normal" },
    { path: "./fonts/Manrope-Light.ttf", weight: "300", style: "normal" },
    { path: "./fonts/Manrope-Regular.ttf", weight: "400", style: "normal" },
    { path: "./fonts/Manrope-Medium.ttf", weight: "500", style: "normal" },
    { path: "./fonts/Manrope-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "./fonts/Manrope-Bold.ttf", weight: "700", style: "normal" },
    { path: "./fonts/Manrope-ExtraBold.ttf", weight: "800", style: "normal" },
  ],
});

export const metadata: Metadata = {
  title: "Organiq Web",
  description: "Planejamento inteligente de rotina, tarefas e lembretes.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="pt-BR" className={`${manrope.variable} h-full antialiased`}>
      <body className="min-h-full bg-[var(--color-background)] text-[var(--color-text)]">
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}
