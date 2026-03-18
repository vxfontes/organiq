"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  ConfirmInboxRequest,
  HomeDashboardResponse,
  InboxItemResponse,
  InboxSuggestion,
  TaskResponse,
} from "@/shared/types/api";
import { formatDate, formatTime, greetingByHour } from "@/shared/utils/date";
import { Spinner } from "@/shared/ui/spinner";
import { StatusPill } from "@/shared/ui/status-pill";

type QuickAddState = "idle" | "creating" | "reprocessing" | "confirming" | "done" | "error";

function pickSuggestion(item: InboxItemResponse): InboxSuggestion | null {
  if (item.suggestion) return item.suggestion;
  if (item.suggestions && item.suggestions.length > 0) return item.suggestions[0];
  return null;
}

export function HomeDashboard() {
  const { token, user } = useSession();

  const [dashboard, setDashboard] = useState<HomeDashboardResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [quickText, setQuickText] = useState("");
  const [quickState, setQuickState] = useState<QuickAddState>("idle");
  const [quickMessage, setQuickMessage] = useState<string | null>(null);

  const greeting = useMemo(() => {
    const hour = new Date().getHours();
    const name = user?.displayName?.split(" ")[0] || "";
    return `${greetingByHour(hour)}${name ? `, ${name}` : ""}`;
  }, [user?.displayName]);

  const loadDashboard = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    setError(null);

    try {
      const response = await httpClient.get<HomeDashboardResponse>("/home/dashboard", {
        token,
      });
      setDashboard(response);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível carregar o dashboard.");
      }
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadDashboard();
  }, [loadDashboard]);

  const toggleTask = useCallback(
    async (task: TaskResponse) => {
      if (!token) return;
      const nextStatus = task.status.toUpperCase() === "DONE" ? "OPEN" : "DONE";

      try {
        await httpClient.patch<TaskResponse>(`/tasks/${task.id}`, {
          token,
          body: { status: nextStatus },
        });
        await loadDashboard();
      } catch (requestError) {
        if (requestError instanceof ApiClientError) {
          setError(mapErrorCode(requestError.code || requestError.message));
        } else {
          setError("Não foi possível atualizar a tarefa.");
        }
      }
    },
    [loadDashboard, token],
  );

  const runQuickAdd = useCallback(async () => {
    if (!token) return;

    const rawText = quickText.trim();
    if (!rawText) {
      setQuickMessage("Digite algo para processar.");
      setQuickState("error");
      return;
    }

    setQuickMessage(null);

    try {
      setQuickState("creating");
      const created = await httpClient.post<InboxItemResponse>("/inbox-items", {
        token,
        body: {
          source: "manual",
          rawText,
        },
      });

      setQuickState("reprocessing");
      const reprocessed = await httpClient.post<InboxItemResponse>(`/inbox-items/${created.id}/reprocess`, {
        token,
      });

      const suggestion = pickSuggestion(reprocessed);
      if (!suggestion || !suggestion.payload || !suggestion.type) {
        setQuickState("error");
        setQuickMessage("A IA não retornou sugestão confirmável. Revise no módulo Create.");
        return;
      }

      const payload: ConfirmInboxRequest = {
        type: suggestion.type,
        title: suggestion.title || rawText,
        payload: suggestion.payload,
        ...(suggestion.flag?.id ? { flagId: suggestion.flag.id } : {}),
        ...(suggestion.subflag?.id ? { subflagId: suggestion.subflag.id } : {}),
      };

      setQuickState("confirming");
      await httpClient.post(`/inbox-items/${created.id}/confirm`, {
        token,
        body: payload,
      });

      setQuickState("done");
      setQuickMessage("Item criado com sucesso.");
      setQuickText("");
      await loadDashboard();

      setTimeout(() => {
        setQuickState("idle");
      }, 1800);
    } catch (requestError) {
      setQuickState("error");
      if (requestError instanceof ApiClientError) {
        setQuickMessage(mapErrorCode(requestError.code || requestError.message));
      } else {
        setQuickMessage("Falha ao processar seu Quick Add.");
      }
    }
  }, [loadDashboard, quickText, token]);

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando dashboard" />
      </section>
    );
  }

  if (error && !dashboard) {
    return (
      <section className="oq-card p-8">
        <p className="text-sm text-[var(--color-danger-600)]">{error}</p>
        <button type="button" className="mt-4 oq-button oq-button-secondary" onClick={() => void loadDashboard()}>
          Tentar novamente
        </button>
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <p className="text-sm text-[var(--color-text-muted)]">{greeting}</p>
        <h1 className="mt-1 text-3xl font-semibold tracking-tight">Visão da sua rotina</h1>

        <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Progresso do dia</p>
            <p className="mt-2 text-2xl font-semibold">{Math.round((dashboard?.day_progress.progress_percent || 0) * 100)}%</p>
            <p className="text-xs text-[var(--color-text-muted)]">
              {dashboard?.day_progress.tasks_done || 0}/{dashboard?.day_progress.tasks_total || 0} tarefas
            </p>
          </article>
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Rotinas concluídas</p>
            <p className="mt-2 text-2xl font-semibold">
              {dashboard?.day_progress.routines_done || 0}/{dashboard?.day_progress.routines_total || 0}
            </p>
          </article>
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Eventos hoje</p>
            <p className="mt-2 text-2xl font-semibold">{dashboard?.events_today_count || 0}</p>
          </article>
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Lembretes hoje</p>
            <p className="mt-2 text-2xl font-semibold">{dashboard?.reminders_today_count || 0}</p>
          </article>
        </div>
      </section>

      <section className="oq-card p-6">
        <div className="flex items-center justify-between gap-3">
          <div>
            <h2 className="text-xl font-semibold tracking-tight">Quick Add</h2>
            <p className="text-sm text-[var(--color-text-muted)]">Texto livre com confirmação automática da IA.</p>
          </div>
          <StatusPill status={quickState.toUpperCase()} />
        </div>

        <div className="mt-4 grid gap-3">
          <textarea
            className="oq-textarea"
            placeholder="Ex: marcar dentista amanhã 14h e comprar ração"
            value={quickText}
            onChange={(event) => setQuickText(event.target.value)}
          />

          <div className="flex items-center gap-3">
            <button
              type="button"
              className="oq-button oq-button-primary"
              onClick={() => void runQuickAdd()}
              disabled={quickState === "creating" || quickState === "reprocessing" || quickState === "confirming"}
            >
              {quickState === "creating" && "Criando..."}
              {quickState === "reprocessing" && "Processando IA..."}
              {quickState === "confirming" && "Confirmando..."}
              {(quickState === "idle" || quickState === "done" || quickState === "error") && "Criar por IA"}
            </button>
            <button type="button" className="oq-button oq-button-ghost" onClick={() => setQuickText("")}>
              Limpar
            </button>
          </div>

          {quickMessage ? <p className="text-sm text-[var(--color-text-muted)]">{quickMessage}</p> : null}
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-2">
        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Próximas ações</h2>
          <ul className="mt-4 space-y-3">
            {(dashboard?.timeline || []).slice(0, 6).map((item) => (
              <li key={item.id} className="rounded-xl border border-[var(--color-border)] bg-white px-3 py-2">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <p className="font-medium">{item.title}</p>
                    <p className="text-xs text-[var(--color-text-muted)]">
                      {formatDate(item.scheduled_time)} às {formatTime(item.scheduled_time)}
                      {item.subtitle ? ` · ${item.subtitle}` : ""}
                    </p>
                  </div>
                  <StatusPill
                    status={item.is_overdue ? "OVERDUE" : item.is_completed ? "DONE" : item.item_type.toUpperCase()}
                  />
                </div>
              </li>
            ))}

            {dashboard?.timeline?.length === 0 ? (
              <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                Nenhuma ação na timeline para hoje.
              </li>
            ) : null}
          </ul>
        </article>

        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Tarefas foco</h2>
          <ul className="mt-4 space-y-3">
            {(dashboard?.focus_tasks || []).slice(0, 6).map((task) => {
              const isDone = task.status.toUpperCase() === "DONE";
              return (
                <li key={task.id} className="rounded-xl border border-[var(--color-border)] bg-white px-3 py-2">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className={isDone ? "font-medium line-through text-[var(--color-text-muted)]" : "font-medium"}>
                        {task.title}
                      </p>
                      <p className="text-xs text-[var(--color-text-muted)]">{task.dueAt ? `Prazo: ${formatDate(task.dueAt)}` : "Sem prazo"}</p>
                    </div>
                    <button type="button" className="oq-button oq-button-secondary" onClick={() => void toggleTask(task)}>
                      {isDone ? "Reabrir" : "Concluir"}
                    </button>
                  </div>
                </li>
              );
            })}

            {dashboard?.focus_tasks?.length === 0 ? (
              <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                Sem tarefas foco no momento.
              </li>
            ) : null}
          </ul>
        </article>
      </section>

      {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
