"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  CursorListResponse,
  RoutineResponse,
  RoutineTodaySummaryResponse,
} from "@/shared/types/api";
import { Spinner } from "@/shared/ui/spinner";

const weekdayOptions = [
  { value: 1, label: "Seg" },
  { value: 2, label: "Ter" },
  { value: 3, label: "Qua" },
  { value: 4, label: "Qui" },
  { value: 5, label: "Sex" },
  { value: 6, label: "Sáb" },
  { value: 0, label: "Dom" },
];

function toWeekdayLabel(values: number[]): string {
  const byValue = new Map(weekdayOptions.map((item) => [item.value, item.label]));
  return values.map((value) => byValue.get(value) || value).join(", ");
}

export function RoutinesBoard() {
  const { token } = useSession();

  const [routines, setRoutines] = useState<RoutineResponse[]>([]);
  const [summary, setSummary] = useState<RoutineTodaySummaryResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [title, setTitle] = useState("");
  const [startTime, setStartTime] = useState("08:00");
  const [endTime, setEndTime] = useState("09:00");
  const [weekdays, setWeekdays] = useState<number[]>([1, 2, 3, 4, 5]);

  const loadData = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const [routinesResponse, summaryResponse] = await Promise.all([
        httpClient.get<CursorListResponse<RoutineResponse>>("/routines", { token }),
        httpClient.get<RoutineTodaySummaryResponse>("/routines/today/summary", { token }),
      ]);

      setRoutines(routinesResponse.items || []);
      setSummary(summaryResponse);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível carregar as rotinas.");
      }
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const completedToday = useMemo(() => routines.filter((routine) => routine.isCompletedToday).length, [routines]);

  const createRoutine = async () => {
    if (!token || saving) return;

    if (!title.trim()) {
      setError("Informe um título para a rotina.");
      return;
    }

    if (weekdays.length === 0) {
      setError("Selecione ao menos um dia da semana.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      await httpClient.post<RoutineResponse>("/routines", {
        token,
        body: {
          title: title.trim(),
          weekdays,
          startTime,
          endTime,
          recurrenceType: "weekly",
          startsOn: new Date().toISOString().slice(0, 10),
        },
      });

      setTitle("");
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar a rotina.");
      }
    } finally {
      setSaving(false);
    }
  };

  const toggleRoutine = async (routine: RoutineResponse) => {
    if (!token) return;

    try {
      await httpClient.patch(`/routines/${routine.id}/toggle`, {
        token,
        body: { isActive: !routine.isActive },
      });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível atualizar a rotina.");
      }
    }
  };

  const toggleComplete = async (routine: RoutineResponse) => {
    if (!token) return;

    try {
      if (routine.isCompletedToday) {
        const today = new Date().toISOString().slice(0, 10);
        await httpClient.delete(`/routines/${routine.id}/complete/${today}`, { token });
      } else {
        await httpClient.post(`/routines/${routine.id}/complete`, { token, body: {} });
      }
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível atualizar conclusão da rotina.");
      }
    }
  };

  const deleteRoutine = async (id: string) => {
    if (!token) return;
    try {
      await httpClient.delete(`/routines/${id}`, { token });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir a rotina.");
      }
    }
  };

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando cronograma" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <h1 className="text-2xl font-semibold tracking-tight">Cronograma</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">Gerencie suas rotinas recorrentes com controle diário.</p>

        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Rotinas totais</p>
            <p className="mt-1 text-2xl font-semibold">{routines.length}</p>
          </article>
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Concluídas hoje</p>
            <p className="mt-1 text-2xl font-semibold">{completedToday}</p>
          </article>
          <article className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
            <p className="text-xs text-[var(--color-text-muted)]">Resumo do dia</p>
            <p className="mt-1 text-2xl font-semibold">{summary?.completed || 0}/{summary?.total || 0}</p>
          </article>
        </div>
      </section>

      <section className="oq-card p-6">
        <h2 className="text-xl font-semibold tracking-tight">Nova rotina</h2>

        <div className="mt-4 grid gap-3 lg:grid-cols-3">
          <label className="block lg:col-span-3">
            <span className="mb-2 block text-sm font-medium">Título</span>
            <input
              className="oq-input"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Ex: Revisar planejamento diário"
            />
          </label>

          <label className="block">
            <span className="mb-2 block text-sm font-medium">Início</span>
            <input className="oq-input" type="time" value={startTime} onChange={(event) => setStartTime(event.target.value)} />
          </label>

          <label className="block">
            <span className="mb-2 block text-sm font-medium">Fim</span>
            <input className="oq-input" type="time" value={endTime} onChange={(event) => setEndTime(event.target.value)} />
          </label>

          <div className="block lg:col-span-3">
            <span className="mb-2 block text-sm font-medium">Dias da semana</span>
            <div className="flex flex-wrap gap-2">
              {weekdayOptions.map((option) => {
                const selected = weekdays.includes(option.value);
                return (
                  <button
                    key={option.value}
                    type="button"
                    className={selected ? "oq-button oq-button-secondary" : "oq-button oq-button-ghost"}
                    onClick={() => {
                      setWeekdays((current) =>
                        current.includes(option.value)
                          ? current.filter((item) => item !== option.value)
                          : [...current, option.value],
                      );
                    }}
                  >
                    {option.label}
                  </button>
                );
              })}
            </div>
          </div>

          <button type="button" className="oq-button oq-button-primary lg:col-span-3" onClick={() => void createRoutine()} disabled={saving}>
            {saving ? "Salvando..." : "Criar rotina"}
          </button>
        </div>
      </section>

      <section className="oq-card p-6">
        <h2 className="text-xl font-semibold tracking-tight">Minhas rotinas</h2>

        <ul className="mt-4 space-y-3">
          {routines.map((routine) => (
            <li key={routine.id} className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-semibold">{routine.title}</p>
                  <p className="text-xs text-[var(--color-text-muted)]">
                    {routine.startTime} - {routine.endTime} · {toWeekdayLabel(routine.weekdays)}
                  </p>
                </div>
                <div className="flex flex-wrap gap-2">
                  <button type="button" className="oq-button oq-button-ghost" onClick={() => void toggleRoutine(routine)}>
                    {routine.isActive ? "Desativar" : "Ativar"}
                  </button>
                  <button type="button" className="oq-button oq-button-secondary" onClick={() => void toggleComplete(routine)}>
                    {routine.isCompletedToday ? "Desfazer hoje" : "Concluir hoje"}
                  </button>
                  <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteRoutine(routine.id)}>
                    Excluir
                  </button>
                </div>
              </div>
            </li>
          ))}

          {routines.length === 0 ? (
            <li className="rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
              Nenhuma rotina cadastrada ainda.
            </li>
          ) : null}
        </ul>

        {error ? <p className="mt-4 text-sm text-[var(--color-danger-600)]">{error}</p> : null}
      </section>
    </div>
  );
}
