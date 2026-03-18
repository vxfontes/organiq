"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";

import { useSession } from "@/shared/auth/session";

type Mode = "login" | "signup";

function validateEmail(email: string): string | null {
  const normalized = email.trim();
  if (!normalized) return "Informe seu email.";
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!regex.test(normalized)) return "Email inválido.";
  return null;
}

function validatePassword(password: string): string | null {
  const normalized = password.trim();
  if (!normalized) return "Informe sua senha.";
  // if (normalized.length < 8) return "Senha muito curta (mínimo 8 caracteres).";
  return null;
}

function validateDisplayName(displayName: string): string | null {
  const normalized = displayName.trim();
  if (!normalized) return "Informe seu nome.";
  if (normalized.length < 2) return "Nome muito curto.";
  return null;
}

export function AuthFormCard({ mode }: { mode: Mode }) {
  const router = useRouter();
  const { login, signup, error, clearError } = useSession();

  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [localError, setLocalError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isSignup = mode === "signup";

  const title = isSignup ? "Criar conta" : "Entrar";
  const subtitle = isSignup
    ? "Monte sua rotina inteligente em poucos passos."
    : "Acesse sua conta para continuar.";

  const helperAction = useMemo(
    () =>
      isSignup
        ? { href: "/auth/login", label: "Já tenho conta" }
        : { href: "/auth/signup", label: "Criar uma conta" },
    [isSignup],
  );

  const submit = async () => {
    if (isSubmitting) return;

    clearError();
    setLocalError(null);

    const nameError = isSignup ? validateDisplayName(displayName) : null;
    const emailError = validateEmail(email);
    const passwordError = validatePassword(password);

    const validationError = nameError || emailError || passwordError;
    if (validationError) {
      setLocalError(validationError);
      return;
    }

    setIsSubmitting(true);

    const ok = isSignup
      ? await signup({ displayName: displayName.trim(), email: email.trim(), password: password.trim() })
      : await login({ email: email.trim(), password: password.trim() });

    setIsSubmitting(false);

    if (ok) {
      router.replace("/app/home");
    }
  };

  return (
    <section className="oq-card w-full max-w-md p-8">
      <div className="flex items-center justify-center">
        <Image src="/app-icon.png" alt="Organiq" width={64} height={64} className="h-16 w-16" />
      </div>

      <h1 className="mt-5 text-center text-2xl font-semibold tracking-tight">{title}</h1>
      <p className="mt-2 text-center text-sm text-[var(--color-text-muted)]">{subtitle}</p>

      <form
        className="mt-6 space-y-4"
        onSubmit={(event) => {
          event.preventDefault();
          void submit();
        }}
      >
        {isSignup ? (
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-[var(--color-text)]">Nome completo</span>
            <input
              className="oq-input"
              type="text"
              placeholder="Como podemos te chamar?"
              value={displayName}
              onChange={(event) => setDisplayName(event.target.value)}
            />
          </label>
        ) : null}

        <label className="block">
          <span className="mb-2 block text-sm font-medium text-[var(--color-text)]">Email</span>
          <input
            className="oq-input"
            type="email"
            placeholder="voce@exemplo.com"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
        </label>

        <label className="block">
          <span className="mb-2 block text-sm font-medium text-[var(--color-text)]">Senha</span>
          <input
            className="oq-input"
            type="password"
            placeholder={isSignup ? "Crie uma senha segura" : "Digite sua senha"}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
        </label>

        {localError || error ? (
          <div className="rounded-xl border border-[var(--color-danger-600)]/25 bg-[color-mix(in_oklab,var(--color-danger-600)_12%,white)] p-3 text-sm text-[var(--color-danger-600)]">
            {localError || error}
          </div>
        ) : null}

        <button type="submit" className="oq-button oq-button-primary w-full" disabled={isSubmitting}>
          {isSubmitting ? "Carregando..." : title}
        </button>

        <Link href={helperAction.href} className="oq-button oq-button-ghost flex w-full items-center justify-center">
          {helperAction.label}
        </Link>
      </form>
    </section>
  );
}
