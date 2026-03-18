"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { env } from "@/shared/config/env";
import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  ActionStatusResponse,
  DailySummaryTokenResponse,
  NotificationPreferencesResponse,
  UpdateNotificationPreferencesRequest,
} from "@/shared/types/api";
import { formatDateTime } from "@/shared/utils/date";
import { Spinner } from "@/shared/ui/spinner";

type PreferencesForm = {
  remindersEnabled: boolean;
  reminderAtTime: boolean;
  reminderLeadMinsText: string;
  eventsEnabled: boolean;
  eventAtTime: boolean;
  eventLeadMinsText: string;
  tasksEnabled: boolean;
  taskAtTime: boolean;
  taskLeadMinsText: string;
  routinesEnabled: boolean;
  routineAtTime: boolean;
  routineLeadMinsText: string;
  quietHoursEnabled: boolean;
  quietStart: string;
  quietEnd: string;
  dailyDigestEnabled: boolean;
  dailyDigestHour: number;
};

function leadMinsToText(values: number[]): string {
  return values.join(", ");
}

function parseLeadMins(value: string): number[] {
  return [...new Set(
    value
      .split(",")
      .map((item) => Number(item.trim()))
      .filter((item) => Number.isInteger(item) && item >= 0),
  )].sort((a, b) => a - b);
}

function toForm(prefs: NotificationPreferencesResponse): PreferencesForm {
  return {
    remindersEnabled: prefs.remindersEnabled,
    reminderAtTime: prefs.reminderAtTime,
    reminderLeadMinsText: leadMinsToText(prefs.reminderLeadMins || []),
    eventsEnabled: prefs.eventsEnabled,
    eventAtTime: prefs.eventAtTime,
    eventLeadMinsText: leadMinsToText(prefs.eventLeadMins || []),
    tasksEnabled: prefs.tasksEnabled,
    taskAtTime: prefs.taskAtTime,
    taskLeadMinsText: leadMinsToText(prefs.taskLeadMins || []),
    routinesEnabled: prefs.routinesEnabled,
    routineAtTime: prefs.routineAtTime,
    routineLeadMinsText: leadMinsToText(prefs.routineLeadMins || []),
    quietHoursEnabled: prefs.quietHoursEnabled,
    quietStart: prefs.quietStart || "",
    quietEnd: prefs.quietEnd || "",
    dailyDigestEnabled: prefs.dailyDigestEnabled,
    dailyDigestHour: prefs.dailyDigestHour,
  };
}

function toPayload(form: PreferencesForm): UpdateNotificationPreferencesRequest {
  const clampedHour = Math.max(0, Math.min(23, Number(form.dailyDigestHour) || 0));
  return {
    remindersEnabled: form.remindersEnabled,
    reminderAtTime: form.reminderAtTime,
    reminderLeadMins: parseLeadMins(form.reminderLeadMinsText),
    eventsEnabled: form.eventsEnabled,
    eventAtTime: form.eventAtTime,
    eventLeadMins: parseLeadMins(form.eventLeadMinsText),
    tasksEnabled: form.tasksEnabled,
    taskAtTime: form.taskAtTime,
    taskLeadMins: parseLeadMins(form.taskLeadMinsText),
    routinesEnabled: form.routinesEnabled,
    routineAtTime: form.routineAtTime,
    routineLeadMins: parseLeadMins(form.routineLeadMinsText),
    quietHoursEnabled: form.quietHoursEnabled,
    quietStart: form.quietStart.trim() || null,
    quietEnd: form.quietEnd.trim() || null,
    dailyDigestEnabled: form.dailyDigestEnabled,
    dailyDigestHour: clampedHour,
  };
}

type ModuleCardProps = {
  title: string;
  enabled: boolean;
  atTime: boolean;
  leadMinsText: string;
  onChangeEnabled: (value: boolean) => void;
  onChangeAtTime: (value: boolean) => void;
  onChangeLeadMins: (value: string) => void;
};

function ModuleNotificationCard({
  title,
  enabled,
  atTime,
  leadMinsText,
  onChangeEnabled,
  onChangeAtTime,
  onChangeLeadMins,
}: ModuleCardProps) {
  return (
    <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
      <h3 className="font-semibold">{title}</h3>
      <div className="mt-3 grid gap-3">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={enabled} onChange={(event) => onChangeEnabled(event.target.checked)} />
          Habilitar modulo
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={atTime} onChange={(event) => onChangeAtTime(event.target.checked)} />
          Notificar no horario exato
        </label>
        <label className="block">
          <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Antecedencia (min) separados por virgula</span>
          <input
            className="oq-input"
            placeholder="5, 10, 30"
            value={leadMinsText}
            onChange={(event) => onChangeLeadMins(event.target.value)}
          />
        </label>
      </div>
    </article>
  );
}

export function NotificationsSettings() {
  const { token } = useSession();

  const [prefs, setPrefs] = useState<NotificationPreferencesResponse | null>(null);
  const [form, setForm] = useState<PreferencesForm | null>(null);
  const [dailySummaryToken, setDailySummaryToken] = useState<DailySummaryTokenResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [runningTestPush, setRunningTestPush] = useState(false);
  const [runningTestDigest, setRunningTestDigest] = useState(false);
  const [rotatingToken, setRotatingToken] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const onApiError = (requestError: unknown, fallbackMessage: string) => {
    if (requestError instanceof ApiClientError) {
      setError(mapErrorCode(requestError.code || requestError.message));
      return;
    }
    setError(fallbackMessage);
  };

  const loadData = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);
    setMessage(null);

    try {
      const [prefsResult, tokenResult] = await Promise.allSettled([
        httpClient.get<NotificationPreferencesResponse>("/notification-preferences", { token }),
        httpClient.get<DailySummaryTokenResponse>("/notification-preferences/daily-summary-token", { token }),
      ]);

      if (prefsResult.status === "fulfilled") {
        setPrefs(prefsResult.value);
        setForm(toForm(prefsResult.value));
      } else {
        throw prefsResult.reason;
      }

      if (tokenResult.status === "fulfilled") {
        setDailySummaryToken(tokenResult.value);
      } else {
        setDailySummaryToken(null);
      }
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel carregar configuracoes de notificacao.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const digestPublicUrl = useMemo(() => {
    if (!dailySummaryToken) return "";
    if (dailySummaryToken.url.startsWith("http://") || dailySummaryToken.url.startsWith("https://")) {
      return dailySummaryToken.url;
    }
    return `${env.apiHost}${dailySummaryToken.url}`;
  }, [dailySummaryToken]);

  const savePreferences = async () => {
    if (!token || !form || saving) return;

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      const response = await httpClient.put<NotificationPreferencesResponse>("/notification-preferences", {
        token,
        body: toPayload(form),
      });
      setPrefs(response);
      setForm(toForm(response));
      setMessage("Preferencias atualizadas.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel salvar preferencias.");
    } finally {
      setSaving(false);
    }
  };

  const rotateToken = async () => {
    if (!token || rotatingToken) return;

    setRotatingToken(true);
    setError(null);
    setMessage(null);

    try {
      const response = await httpClient.post<DailySummaryTokenResponse>("/notification-preferences/daily-summary-token/rotate", {
        token,
      });
      setDailySummaryToken(response);
      setMessage("Token diario rotacionado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel rotacionar token.");
    } finally {
      setRotatingToken(false);
    }
  };

  const sendTestPush = async () => {
    if (!token || runningTestPush) return;

    setRunningTestPush(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.post<ActionStatusResponse>("/notifications/test", { token });
      setMessage("Teste de push solicitado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel enviar teste de push.");
    } finally {
      setRunningTestPush(false);
    }
  };

  const sendTestDigest = async () => {
    if (!token || runningTestDigest) return;

    setRunningTestDigest(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.post<ActionStatusResponse>("/digest/test", { token });
      setMessage("Teste de digest solicitado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel enviar teste de digest.");
    } finally {
      setRunningTestDigest(false);
    }
  };

  const copyDigestLink = async () => {
    if (!digestPublicUrl) return;
    try {
      if (!navigator.clipboard?.writeText) {
        setMessage("Clipboard indisponivel neste navegador.");
        return;
      }
      await navigator.clipboard.writeText(digestPublicUrl);
      setMessage("Link copiado.");
    } catch {
      setError("Nao foi possivel copiar link.");
    }
  };

  if (loading || !form) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando preferencias de notificacao" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Notificacoes</h1>
            <p className="mt-2 text-sm text-[var(--color-text-muted)]">
              Controle notificacoes por modulo, janela silenciosa e resumo diario.
            </p>
          </div>
          <button type="button" className="oq-button oq-button-primary" onClick={() => void savePreferences()} disabled={saving}>
            {saving ? "Salvando..." : "Salvar preferencias"}
          </button>
        </div>
      </section>

      <section className="grid gap-4 xl:grid-cols-2">
        <ModuleNotificationCard
          title="Lembretes"
          enabled={form.remindersEnabled}
          atTime={form.reminderAtTime}
          leadMinsText={form.reminderLeadMinsText}
          onChangeEnabled={(value) => setForm((current) => (current ? { ...current, remindersEnabled: value } : current))}
          onChangeAtTime={(value) => setForm((current) => (current ? { ...current, reminderAtTime: value } : current))}
          onChangeLeadMins={(value) => setForm((current) => (current ? { ...current, reminderLeadMinsText: value } : current))}
        />
        <ModuleNotificationCard
          title="Eventos"
          enabled={form.eventsEnabled}
          atTime={form.eventAtTime}
          leadMinsText={form.eventLeadMinsText}
          onChangeEnabled={(value) => setForm((current) => (current ? { ...current, eventsEnabled: value } : current))}
          onChangeAtTime={(value) => setForm((current) => (current ? { ...current, eventAtTime: value } : current))}
          onChangeLeadMins={(value) => setForm((current) => (current ? { ...current, eventLeadMinsText: value } : current))}
        />
        <ModuleNotificationCard
          title="Tarefas"
          enabled={form.tasksEnabled}
          atTime={form.taskAtTime}
          leadMinsText={form.taskLeadMinsText}
          onChangeEnabled={(value) => setForm((current) => (current ? { ...current, tasksEnabled: value } : current))}
          onChangeAtTime={(value) => setForm((current) => (current ? { ...current, taskAtTime: value } : current))}
          onChangeLeadMins={(value) => setForm((current) => (current ? { ...current, taskLeadMinsText: value } : current))}
        />
        <ModuleNotificationCard
          title="Rotinas"
          enabled={form.routinesEnabled}
          atTime={form.routineAtTime}
          leadMinsText={form.routineLeadMinsText}
          onChangeEnabled={(value) => setForm((current) => (current ? { ...current, routinesEnabled: value } : current))}
          onChangeAtTime={(value) => setForm((current) => (current ? { ...current, routineAtTime: value } : current))}
          onChangeLeadMins={(value) => setForm((current) => (current ? { ...current, routineLeadMinsText: value } : current))}
        />
      </section>

      <section className="grid gap-6 xl:grid-cols-[1fr_1fr]">
        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Quiet hours</h2>
          <div className="mt-4 grid gap-3">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={form.quietHoursEnabled}
                onChange={(event) => setForm((current) => (current ? { ...current, quietHoursEnabled: event.target.checked } : current))}
              />
              Habilitar periodo silencioso
            </label>

            <div className="grid gap-3 sm:grid-cols-2">
              <label className="block">
                <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Inicio</span>
                <input
                  className="oq-input"
                  type="time"
                  value={form.quietStart}
                  onChange={(event) => setForm((current) => (current ? { ...current, quietStart: event.target.value } : current))}
                />
              </label>
              <label className="block">
                <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Fim</span>
                <input
                  className="oq-input"
                  type="time"
                  value={form.quietEnd}
                  onChange={(event) => setForm((current) => (current ? { ...current, quietEnd: event.target.value } : current))}
                />
              </label>
            </div>
          </div>
        </article>

        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Resumo diario</h2>
          <div className="mt-4 grid gap-3">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={form.dailyDigestEnabled}
                onChange={(event) => setForm((current) => (current ? { ...current, dailyDigestEnabled: event.target.checked } : current))}
              />
              Receber digest diario por email
            </label>

            <label className="block">
              <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Hora do digest (0-23)</span>
              <input
                className="oq-input"
                type="number"
                min={0}
                max={23}
                value={form.dailyDigestHour}
                onChange={(event) =>
                  setForm((current) => (current ? { ...current, dailyDigestHour: Number(event.target.value) || 0 } : current))
                }
              />
            </label>
          </div>
        </article>
      </section>

      <section className="grid gap-6 xl:grid-cols-[1fr_1fr]">
        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Token do resumo publico</h2>
          <p className="mt-2 text-sm text-[var(--color-text-muted)]">
            Use este link para abrir o resumo diario sem JWT. Rotacione o token quando necessario.
          </p>
          <div className="mt-4 space-y-3">
            <input className="oq-input" readOnly value={dailySummaryToken?.token || ""} placeholder="Token nao encontrado" />
            <input className="oq-input" readOnly value={digestPublicUrl} placeholder="URL nao encontrada" />
            <div className="flex flex-wrap gap-2">
              <button type="button" className="oq-button oq-button-secondary" onClick={() => void copyDigestLink()} disabled={!digestPublicUrl}>
                Copiar link
              </button>
              <button type="button" className="oq-button oq-button-ghost" onClick={() => void rotateToken()} disabled={rotatingToken}>
                {rotatingToken ? "Rotacionando..." : "Rotacionar token"}
              </button>
            </div>
          </div>
        </article>

        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Testes</h2>
          <p className="mt-2 text-sm text-[var(--color-text-muted)]">
            Dispare testes para validar configuracao de push e email no ambiente atual.
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <button type="button" className="oq-button oq-button-secondary" onClick={() => void sendTestPush()} disabled={runningTestPush}>
              {runningTestPush ? "Enviando push..." : "Enviar push de teste"}
            </button>
            <button type="button" className="oq-button oq-button-ghost" onClick={() => void sendTestDigest()} disabled={runningTestDigest}>
              {runningTestDigest ? "Enviando digest..." : "Enviar digest de teste"}
            </button>
          </div>

          <div className="mt-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface-soft)] p-3 text-xs text-[var(--color-text-muted)]">
            Atualizado em: {prefs?.updatedAt ? formatDateTime(prefs.updatedAt) : "-"}
          </div>
        </article>
      </section>

      {message ? <p className="text-sm text-[var(--color-success-600)]">{message}</p> : null}
      {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
