"use client";

import { useCallback, useEffect, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  CursorListResponse,
  ReminderResponse,
  TaskResponse,
} from "@/shared/types/api";
import { combineDateTimeToIso, formatDateTime } from "@/shared/utils/date";
import { FlagSubflagFields } from "@/shared/ui/flag-subflag-fields";
import { Spinner } from "@/shared/ui/spinner";

type ContextSelection = {
  flagId?: string;
  subflagId?: string;
};

export function RemindersBoard() {
  const { token } = useSession();

  const [tasks, setTasks] = useState<TaskResponse[]>([]);
  const [reminders, setReminders] = useState<ReminderResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [taskTitle, setTaskTitle] = useState("");
  const [taskDescription, setTaskDescription] = useState("");
  const [taskDate, setTaskDate] = useState("");
  const [taskTime, setTaskTime] = useState("");
  const [taskContext, setTaskContext] = useState<ContextSelection>({});

  const [reminderTitle, setReminderTitle] = useState("");
  const [reminderDate, setReminderDate] = useState("");
  const [reminderTime, setReminderTime] = useState("");
  const [reminderContext, setReminderContext] = useState<ContextSelection>({});

  const [savingTask, setSavingTask] = useState(false);
  const [savingReminder, setSavingReminder] = useState(false);

  const loadData = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const [tasksResponse, remindersResponse] = await Promise.all([
        httpClient.get<CursorListResponse<TaskResponse>>("/tasks", { token }),
        httpClient.get<CursorListResponse<ReminderResponse>>("/reminders", { token }),
      ]);

      setTasks(tasksResponse.items || []);
      setReminders(remindersResponse.items || []);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível carregar tarefas e lembretes.");
      }
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const createTask = async () => {
    if (!token || savingTask) return;
    if (!taskTitle.trim()) {
      setError("Informe o título da tarefa.");
      return;
    }

    setSavingTask(true);
    setError(null);

    try {
      await httpClient.post<TaskResponse>("/tasks", {
        token,
        body: {
          title: taskTitle.trim(),
          description: taskDescription.trim() || undefined,
          dueAt: combineDateTimeToIso(taskDate, taskTime) || undefined,
          ...taskContext,
        },
      });

      setTaskTitle("");
      setTaskDescription("");
      setTaskDate("");
      setTaskTime("");
      setTaskContext({});
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar tarefa.");
      }
    } finally {
      setSavingTask(false);
    }
  };

  const createReminder = async () => {
    if (!token || savingReminder) return;
    if (!reminderTitle.trim()) {
      setError("Informe o título do lembrete.");
      return;
    }

    setSavingReminder(true);
    setError(null);

    try {
      await httpClient.post<ReminderResponse>("/reminders", {
        token,
        body: {
          title: reminderTitle.trim(),
          remindAt: combineDateTimeToIso(reminderDate, reminderTime) || undefined,
          ...reminderContext,
        },
      });

      setReminderTitle("");
      setReminderDate("");
      setReminderTime("");
      setReminderContext({});
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar lembrete.");
      }
    } finally {
      setSavingReminder(false);
    }
  };

  const toggleTask = async (task: TaskResponse) => {
    if (!token) return;
    const nextStatus = task.status.toUpperCase() === "DONE" ? "OPEN" : "DONE";

    try {
      await httpClient.patch(`/tasks/${task.id}`, {
        token,
        body: { status: nextStatus },
      });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível atualizar tarefa.");
      }
    }
  };

  const toggleReminder = async (reminder: ReminderResponse) => {
    if (!token) return;
    const nextStatus = reminder.status.toUpperCase() === "DONE" ? "OPEN" : "DONE";

    try {
      await httpClient.patch(`/reminders/${reminder.id}`, {
        token,
        body: { status: nextStatus },
      });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível atualizar lembrete.");
      }
    }
  };

  const deleteTask = async (id: string) => {
    if (!token) return;
    try {
      await httpClient.delete(`/tasks/${id}`, { token });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir tarefa.");
      }
    }
  };

  const deleteReminder = async (id: string) => {
    if (!token) return;
    try {
      await httpClient.delete(`/reminders/${id}`, { token });
      await loadData();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir lembrete.");
      }
    }
  };

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando lembretes e tarefas" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <h1 className="text-2xl font-semibold tracking-tight">Lembretes e Tarefas</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">Organize suas entregas e acionamentos com contexto e prazo.</p>
      </section>

      <section className="grid gap-6 xl:grid-cols-2">
        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Nova tarefa</h2>
          <div className="mt-4 grid gap-3">
            <input className="oq-input" placeholder="Título da tarefa" value={taskTitle} onChange={(event) => setTaskTitle(event.target.value)} />
            <textarea
              className="oq-textarea"
              placeholder="Descrição (opcional)"
              value={taskDescription}
              onChange={(event) => setTaskDescription(event.target.value)}
            />
            <div className="grid gap-3 sm:grid-cols-2">
              <input className="oq-input" type="date" value={taskDate} onChange={(event) => setTaskDate(event.target.value)} />
              <input className="oq-input" type="time" value={taskTime} onChange={(event) => setTaskTime(event.target.value)} />
            </div>

            <FlagSubflagFields
              token={token}
              flagId={taskContext.flagId}
              subflagId={taskContext.subflagId}
              onChange={(value) => setTaskContext(value)}
            />

            <button type="button" className="oq-button oq-button-primary" onClick={() => void createTask()} disabled={savingTask}>
              {savingTask ? "Salvando..." : "Criar tarefa"}
            </button>
          </div>

          <ul className="mt-6 space-y-3">
            {tasks.map((task) => {
              const done = task.status.toUpperCase() === "DONE";
              return (
                <li key={task.id} className="rounded-2xl border border-[var(--color-border)] bg-white p-3">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <p className={done ? "font-medium line-through text-[var(--color-text-muted)]" : "font-medium"}>{task.title}</p>
                      <p className="text-xs text-[var(--color-text-muted)]">
                        {task.dueAt ? formatDateTime(task.dueAt) : "Sem prazo"}
                        {task.flag?.name ? ` · ${task.flag.name}` : ""}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <button type="button" className="oq-button oq-button-secondary" onClick={() => void toggleTask(task)}>
                        {done ? "Reabrir" : "Concluir"}
                      </button>
                      <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteTask(task.id)}>
                        Excluir
                      </button>
                    </div>
                  </div>
                </li>
              );
            })}

            {tasks.length === 0 ? (
              <li className="rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                Nenhuma tarefa cadastrada.
              </li>
            ) : null}
          </ul>
        </article>

        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Novo lembrete</h2>
          <div className="mt-4 grid gap-3">
            <input
              className="oq-input"
              placeholder="Título do lembrete"
              value={reminderTitle}
              onChange={(event) => setReminderTitle(event.target.value)}
            />
            <div className="grid gap-3 sm:grid-cols-2">
              <input className="oq-input" type="date" value={reminderDate} onChange={(event) => setReminderDate(event.target.value)} />
              <input className="oq-input" type="time" value={reminderTime} onChange={(event) => setReminderTime(event.target.value)} />
            </div>

            <FlagSubflagFields
              token={token}
              flagId={reminderContext.flagId}
              subflagId={reminderContext.subflagId}
              onChange={(value) => setReminderContext(value)}
            />

            <button
              type="button"
              className="oq-button oq-button-primary"
              onClick={() => void createReminder()}
              disabled={savingReminder}
            >
              {savingReminder ? "Salvando..." : "Criar lembrete"}
            </button>
          </div>

          <ul className="mt-6 space-y-3">
            {reminders.map((reminder) => {
              const done = reminder.status.toUpperCase() === "DONE";
              return (
                <li key={reminder.id} className="rounded-2xl border border-[var(--color-border)] bg-white p-3">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <p className={done ? "font-medium line-through text-[var(--color-text-muted)]" : "font-medium"}>{reminder.title}</p>
                      <p className="text-xs text-[var(--color-text-muted)]">
                        {reminder.remindAt ? formatDateTime(reminder.remindAt) : "Sem horário definido"}
                        {reminder.flag?.name ? ` · ${reminder.flag.name}` : ""}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <button type="button" className="oq-button oq-button-secondary" onClick={() => void toggleReminder(reminder)}>
                        {done ? "Reabrir" : "Concluir"}
                      </button>
                      <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteReminder(reminder.id)}>
                        Excluir
                      </button>
                    </div>
                  </div>
                </li>
              );
            })}

            {reminders.length === 0 ? (
              <li className="rounded-2xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                Nenhum lembrete cadastrado.
              </li>
            ) : null}
          </ul>
        </article>
      </section>

      {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
