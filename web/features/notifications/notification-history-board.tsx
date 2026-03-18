"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type { ActionStatusResponse, CursorListResponse, NotificationLogResponse } from "@/shared/types/api";
import { formatDateTime } from "@/shared/utils/date";
import { StatusPill } from "@/shared/ui/status-pill";
import { Spinner } from "@/shared/ui/spinner";

type ReadFilter = "all" | "unread" | "read";

export function NotificationHistoryBoard() {
  const { token } = useSession();

  const [items, setItems] = useState<NotificationLogResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [filter, setFilter] = useState<ReadFilter>("all");
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const onApiError = (requestError: unknown, fallbackMessage: string) => {
    if (requestError instanceof ApiClientError) {
      setError(mapErrorCode(requestError.code || requestError.message));
      return;
    }
    setError(fallbackMessage);
  };

  const loadNotifications = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const response = await httpClient.get<CursorListResponse<NotificationLogResponse>>("/notifications", {
        token,
        query: {
          limit: 100,
          offset: 0,
        },
      });

      const sortedItems = (response.items || []).slice().sort((a, b) => {
        const left = new Date(a.scheduledFor || a.createdAt).getTime();
        const right = new Date(b.scheduledFor || b.createdAt).getTime();
        return right - left;
      });
      setItems(sortedItems);
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel carregar notificacoes.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadNotifications();
  }, [loadNotifications]);

  const unreadCount = useMemo(() => items.filter((item) => !item.readAt).length, [items]);

  const filteredItems = useMemo(() => {
    if (filter === "all") return items;
    if (filter === "read") return items.filter((item) => Boolean(item.readAt));
    return items.filter((item) => !item.readAt);
  }, [filter, items]);

  const markAsRead = async (id: string) => {
    if (!token || busy) return;

    setBusy(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.patch<ActionStatusResponse>(`/notifications/${id}/read`, { token });
      setItems((current) =>
        current.map((item) =>
          item.id === id
            ? {
                ...item,
                readAt: item.readAt || new Date().toISOString(),
              }
            : item,
        ),
      );
      setMessage("Notificacao marcada como lida.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel marcar notificacao como lida.");
    } finally {
      setBusy(false);
    }
  };

  const markAllAsRead = async () => {
    if (!token || busy || unreadCount === 0) return;

    setBusy(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.patch<ActionStatusResponse>("/notifications/read-all", { token });
      const nowIso = new Date().toISOString();
      setItems((current) =>
        current.map((item) => ({
          ...item,
          readAt: item.readAt || nowIso,
        })),
      );
      setMessage("Todas as notificacoes foram marcadas como lidas.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel marcar todas como lidas.");
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando historico de notificacoes" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Historico de notificacoes</h1>
            <p className="mt-2 text-sm text-[var(--color-text-muted)]">
              Acompanhe envios, leituras e status do canal de notificacoes.
            </p>
          </div>
          <button type="button" className="oq-button oq-button-primary" onClick={() => void markAllAsRead()} disabled={busy || unreadCount === 0}>
            Marcar todas como lidas ({unreadCount})
          </button>
        </div>

        <div className="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            className={filter === "all" ? "oq-button oq-button-secondary" : "oq-button oq-button-ghost"}
            onClick={() => setFilter("all")}
          >
            Todas
          </button>
          <button
            type="button"
            className={filter === "unread" ? "oq-button oq-button-secondary" : "oq-button oq-button-ghost"}
            onClick={() => setFilter("unread")}
          >
            Nao lidas
          </button>
          <button
            type="button"
            className={filter === "read" ? "oq-button oq-button-secondary" : "oq-button oq-button-ghost"}
            onClick={() => setFilter("read")}
          >
            Lidas
          </button>
          <button type="button" className="oq-button oq-button-ghost" onClick={() => void loadNotifications()}>
            Atualizar
          </button>
        </div>
      </section>

      <section className="oq-card p-6">
        <ul className="space-y-3">
          {filteredItems.map((item) => {
            const unread = !item.readAt;

            return (
              <li
                key={item.id}
                className={
                  unread
                    ? "rounded-2xl border border-[var(--color-primary-200)] bg-[var(--color-primary-50)] p-4"
                    : "rounded-2xl border border-[var(--color-border)] bg-white p-4"
                }
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="truncate font-semibold">{item.title}</p>
                      <StatusPill status={item.status} />
                    </div>
                    <p className="mt-1 text-sm text-[var(--color-text-muted)]">{item.body}</p>
                    <p className="mt-2 text-xs uppercase tracking-wide text-[var(--color-text-muted)]">
                      {item.type} · agendado {formatDateTime(item.scheduledFor)} · criado {formatDateTime(item.createdAt)}
                    </p>
                    <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                      {item.readAt ? `Lida em ${formatDateTime(item.readAt)}` : "Ainda nao lida"}
                    </p>
                  </div>

                  {unread ? (
                    <button type="button" className="oq-button oq-button-secondary" onClick={() => void markAsRead(item.id)} disabled={busy}>
                      Marcar como lida
                    </button>
                  ) : null}
                </div>
              </li>
            );
          })}

          {filteredItems.length === 0 ? (
            <li className="rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
              Nenhuma notificacao para o filtro selecionado.
            </li>
          ) : null}
        </ul>
      </section>

      {message ? <p className="text-sm text-[var(--color-success-600)]">{message}</p> : null}
      {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
