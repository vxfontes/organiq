"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type { AgendaResponse, EventResponse } from "@/shared/types/api";
import { combineDateTimeToIso, formatDateTime } from "@/shared/utils/date";
import { FlagSubflagFields } from "@/shared/ui/flag-subflag-fields";
import { Spinner } from "@/shared/ui/spinner";

type AgendaFilter = "all" | "events" | "tasks" | "reminders";

type ContextSelection = {
  flagId?: string;
  subflagId?: string;
};

type FeedItem = {
  id: string;
  kind: "event" | "task" | "reminder";
  title: string;
  date?: string | null;
  subtitle?: string;
};

function isSameDay(isoValue: string | null | undefined, selectedDate: string): boolean {
  if (!isoValue) return false;
  return isoValue.slice(0, 10) === selectedDate;
}

export function EventsBoard() {
  const { token } = useSession();

  const [agenda, setAgenda] = useState<AgendaResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [filter, setFilter] = useState<AgendaFilter>("all");
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().slice(0, 10));

  const [title, setTitle] = useState("");
  const [startDate, setStartDate] = useState(new Date().toISOString().slice(0, 10));
  const [startTime, setStartTime] = useState("09:00");
  const [endTime, setEndTime] = useState("10:00");
  const [location, setLocation] = useState("");
  const [allDay, setAllDay] = useState(false);
  const [context, setContext] = useState<ContextSelection>({});

  const loadAgenda = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const response = await httpClient.get<AgendaResponse>("/agenda", { token });
      setAgenda(response);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível carregar a agenda.");
      }
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadAgenda();
  }, [loadAgenda]);

  const feed = useMemo<FeedItem[]>(() => {
    if (!agenda) return [];

    const eventItems: FeedItem[] = agenda.events
      .filter((item) => isSameDay(item.startAt, selectedDate))
      .map((item) => ({
        id: item.id,
        kind: "event",
        title: item.title,
        date: item.startAt,
        subtitle: item.location || undefined,
      }));

    const taskItems: FeedItem[] = agenda.tasks
      .filter((item) => isSameDay(item.dueAt, selectedDate))
      .map((item) => ({
        id: item.id,
        kind: "task",
        title: item.title,
        date: item.dueAt,
        subtitle: item.status,
      }));

    const reminderItems: FeedItem[] = agenda.reminders
      .filter((item) => isSameDay(item.remindAt, selectedDate))
      .map((item) => ({
        id: item.id,
        kind: "reminder",
        title: item.title,
        date: item.remindAt,
        subtitle: item.status,
      }));

    let items = [...eventItems, ...taskItems, ...reminderItems];
    if (filter !== "all") {
      items = items.filter((item) => item.kind === filter.slice(0, -1));
    }

    return items.sort((a, b) => (a.date || "").localeCompare(b.date || ""));
  }, [agenda, filter, selectedDate]);

  const createEvent = async () => {
    if (!token || saving) return;
    if (!title.trim()) {
      setError("Informe o título do evento.");
      return;
    }

    const startAt = allDay ? `${startDate}T00:00:00.000Z` : combineDateTimeToIso(startDate, startTime);
    const endAt = allDay ? `${startDate}T23:59:59.000Z` : combineDateTimeToIso(startDate, endTime);

    setSaving(true);
    setError(null);

    try {
      await httpClient.post<EventResponse>("/events", {
        token,
        body: {
          title: title.trim(),
          startAt,
          endAt,
          allDay,
          location: location.trim() || undefined,
          ...context,
        },
      });

      setTitle("");
      setLocation("");
      setAllDay(false);
      setContext({});
      await loadAgenda();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar evento.");
      }
    } finally {
      setSaving(false);
    }
  };

  const deleteItem = async (item: FeedItem) => {
    if (!token) return;

    try {
      if (item.kind === "event") {
        await httpClient.delete(`/events/${item.id}`, { token });
      }
      if (item.kind === "task") {
        await httpClient.delete(`/tasks/${item.id}`, { token });
      }
      if (item.kind === "reminder") {
        await httpClient.delete(`/reminders/${item.id}`, { token });
      }

      await loadAgenda();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir item da agenda.");
      }
    }
  };

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando agenda" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <h1 className="text-2xl font-semibold tracking-tight">Agenda</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">Calendário operacional com eventos, tarefas e lembretes por dia.</p>

        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <input className="oq-input" type="date" value={selectedDate} onChange={(event) => setSelectedDate(event.target.value)} />
          <select className="oq-input" value={filter} onChange={(event) => setFilter(event.target.value as AgendaFilter)}>
            <option value="all">Todos</option>
            <option value="events">Eventos</option>
            <option value="tasks">Tarefas</option>
            <option value="reminders">Lembretes</option>
          </select>
          <button type="button" className="oq-button oq-button-ghost" onClick={() => void loadAgenda()}>
            Atualizar
          </button>
        </div>
      </section>

      <section className="oq-card p-6">
        <h2 className="text-xl font-semibold tracking-tight">Criar evento</h2>

        <div className="mt-4 grid gap-3 lg:grid-cols-2">
          <input className="oq-input lg:col-span-2" placeholder="Título do evento" value={title} onChange={(event) => setTitle(event.target.value)} />
          <input className="oq-input" type="date" value={startDate} onChange={(event) => setStartDate(event.target.value)} />
          <label className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] bg-white px-3 py-2">
            <input type="checkbox" checked={allDay} onChange={(event) => setAllDay(event.target.checked)} />
            <span className="text-sm">Dia inteiro</span>
          </label>

          {!allDay ? (
            <>
              <input className="oq-input" type="time" value={startTime} onChange={(event) => setStartTime(event.target.value)} />
              <input className="oq-input" type="time" value={endTime} onChange={(event) => setEndTime(event.target.value)} />
            </>
          ) : null}

          <input className="oq-input lg:col-span-2" placeholder="Local (opcional)" value={location} onChange={(event) => setLocation(event.target.value)} />

          <div className="lg:col-span-2">
            <FlagSubflagFields
              token={token}
              flagId={context.flagId}
              subflagId={context.subflagId}
              onChange={(value) => setContext(value)}
            />
          </div>

          <button type="button" className="oq-button oq-button-primary lg:col-span-2" onClick={() => void createEvent()} disabled={saving}>
            {saving ? "Salvando..." : "Criar evento"}
          </button>
        </div>
      </section>

      <section className="oq-card p-6">
        <h2 className="text-xl font-semibold tracking-tight">Feed do dia</h2>

        <ul className="mt-4 space-y-3">
          {feed.map((item) => (
            <li key={`${item.kind}-${item.id}`} className="rounded-2xl border border-[var(--color-border)] bg-white p-3">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-semibold">{item.title}</p>
                  <p className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">
                    {item.kind} · {item.date ? formatDateTime(item.date) : "Sem data"}
                    {item.subtitle ? ` · ${item.subtitle}` : ""}
                  </p>
                </div>
                <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteItem(item)}>
                  Excluir
                </button>
              </div>
            </li>
          ))}

          {feed.length === 0 ? (
            <li className="rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
              Nenhum item para o filtro e data selecionados.
            </li>
          ) : null}
        </ul>

        {error ? <p className="mt-4 text-sm text-[var(--color-danger-600)]">{error}</p> : null}
      </section>
    </div>
  );
}
