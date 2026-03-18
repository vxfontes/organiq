"use client";

import { useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  ConfirmInboxRequest,
  ConfirmInboxResponse,
  InboxItemResponse,
  InboxSuggestion,
} from "@/shared/types/api";
import { Spinner } from "@/shared/ui/spinner";
import { StatusPill } from "@/shared/ui/status-pill";

type StepState = "idle" | "processing" | "review" | "confirming" | "done";

type LineResult = {
  id: string;
  rawText: string;
  inboxId?: string;
  status: "ready" | "error" | "confirmed";
  error?: string;
  suggestion?: InboxSuggestion;
  editedType?: string;
  editedTitle?: string;
  selected: boolean;
  confirmResult?: ConfirmInboxResponse;
};

function getSuggestion(item: InboxItemResponse): InboxSuggestion | undefined {
  return item.suggestion || item.suggestions?.[0];
}

export function CreateWorkflow() {
  const { token } = useSession();

  const [step, setStep] = useState<StepState>("idle");
  const [input, setInput] = useState("");
  const [lines, setLines] = useState<LineResult[]>([]);
  const [error, setError] = useState<string | null>(null);

  const stats = useMemo(() => {
    const confirmed = lines.filter((line) => line.status === "confirmed");
    return {
      total: lines.length,
      confirmed: confirmed.length,
      tasks: confirmed.filter((line) => line.confirmResult?.task).length,
      reminders: confirmed.filter((line) => line.confirmResult?.reminder).length,
      events: confirmed.filter((line) => line.confirmResult?.event).length,
      shopping: confirmed.filter((line) => line.confirmResult?.shoppingList || line.confirmResult?.shoppingItems?.length).length,
      routines: confirmed.filter((line) => line.confirmResult?.routine).length,
    };
  }, [lines]);

  const processLines = async () => {
    if (!token) return;

    const rawLines = input
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);

    if (rawLines.length === 0) {
      setError("Digite pelo menos uma linha para processar.");
      return;
    }

    setError(null);
    setStep("processing");

    const results: LineResult[] = [];

    for (let index = 0; index < rawLines.length; index += 1) {
      const rawText = rawLines[index];
      const localId = `${Date.now()}-${index}`;

      try {
        const created = await httpClient.post<InboxItemResponse>("/inbox-items", {
          token,
          body: { source: "manual", rawText },
        });

        const reprocessed = await httpClient.post<InboxItemResponse>(`/inbox-items/${created.id}/reprocess`, {
          token,
        });

        const suggestion = getSuggestion(reprocessed);
        if (!suggestion || !suggestion.payload || !suggestion.type) {
          results.push({
            id: localId,
            rawText,
            inboxId: created.id,
            status: "error",
            error: "A IA não retornou sugestão confirmável para esta linha.",
            selected: false,
          });
          continue;
        }

        results.push({
          id: localId,
          rawText,
          inboxId: created.id,
          status: "ready",
          suggestion,
          editedType: suggestion.type,
          editedTitle: suggestion.title,
          selected: true,
        });
      } catch (requestError) {
        const mappedError =
          requestError instanceof ApiClientError
            ? mapErrorCode(requestError.code || requestError.message)
            : "Falha ao processar linha.";

        results.push({
          id: localId,
          rawText,
          status: "error",
          error: mappedError,
          selected: false,
        });
      }
    }

    setLines(results);
    setStep("review");
  };

  const confirmSelected = async () => {
    if (!token) return;

    setStep("confirming");
    const updated = [...lines];

    for (let index = 0; index < updated.length; index += 1) {
      const line = updated[index];
      if (!line.selected || line.status !== "ready" || !line.suggestion || !line.inboxId) {
        continue;
      }

      const payload: ConfirmInboxRequest = {
        type: (line.editedType || line.suggestion.type).trim().toLowerCase(),
        title: (line.editedTitle || line.suggestion.title || line.rawText).trim(),
        payload: line.suggestion.payload,
        ...(line.suggestion.flag?.id ? { flagId: line.suggestion.flag.id } : {}),
        ...(line.suggestion.subflag?.id ? { subflagId: line.suggestion.subflag.id } : {}),
      };

      try {
        const response = await httpClient.post<ConfirmInboxResponse>(`/inbox-items/${line.inboxId}/confirm`, {
          token,
          body: payload,
        });

        updated[index] = {
          ...line,
          status: "confirmed",
          confirmResult: response,
          error: undefined,
        };
      } catch (requestError) {
        const mappedError =
          requestError instanceof ApiClientError
            ? mapErrorCode(requestError.code || requestError.message)
            : "Falha ao confirmar item.";

        updated[index] = {
          ...line,
          status: "error",
          error: mappedError,
        };
      }
    }

    setLines(updated);
    setStep("done");
  };

  const removeCreated = async (line: LineResult) => {
    if (!token || !line.confirmResult) return;

    try {
      if (line.confirmResult.task?.id) {
        await httpClient.delete(`/tasks/${line.confirmResult.task.id}`, { token });
      }
      if (line.confirmResult.reminder?.id) {
        await httpClient.delete(`/reminders/${line.confirmResult.reminder.id}`, { token });
      }
      if (line.confirmResult.event?.id) {
        await httpClient.delete(`/events/${line.confirmResult.event.id}`, { token });
      }
      if (line.confirmResult.routine?.id) {
        await httpClient.delete(`/routines/${line.confirmResult.routine.id}`, { token });
      }
      if (line.confirmResult.shoppingList?.id) {
        await httpClient.delete(`/shopping-lists/${line.confirmResult.shoppingList.id}`, { token });
      }

      setLines((current) =>
        current.map((item) =>
          item.id === line.id
            ? {
                ...item,
                status: "ready",
                confirmResult: undefined,
                error: "Item removido do backend.",
              }
            : item,
        ),
      );
    } catch (requestError) {
      const mappedError =
        requestError instanceof ApiClientError
          ? mapErrorCode(requestError.code || requestError.message)
          : "Não foi possível excluir item criado.";
      setError(mappedError);
    }
  };

  const resetFlow = () => {
    setStep("idle");
    setLines([]);
    setInput("");
    setError(null);
  };

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Create IA</h1>
            <p className="mt-2 text-sm text-[var(--color-text-muted)]">Entrada em lote com revisão e confirmação por linha.</p>
          </div>
          <StatusPill status={step.toUpperCase()} />
        </div>

        <div className="mt-4 grid gap-3">
          <textarea
            className="oq-textarea"
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder={"Ex:\n- comprar frutas e água\n- reunião terça 15h\n- lembrar de pagar internet sexta"}
            disabled={step === "processing" || step === "confirming"}
          />

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className="oq-button oq-button-primary"
              onClick={() => void processLines()}
              disabled={step === "processing" || step === "confirming"}
            >
              {step === "processing" ? "Processando..." : "Processar linhas"}
            </button>

            {step === "review" ? (
              <button type="button" className="oq-button oq-button-secondary" onClick={() => void confirmSelected()}>
                Confirmar selecionados
              </button>
            ) : null}

            {(step === "review" || step === "done") ? (
              <button type="button" className="oq-button oq-button-ghost" onClick={resetFlow}>
                Novo lote
              </button>
            ) : null}
          </div>

          {step === "processing" || step === "confirming" ? <Spinner label="Executando workflow" /> : null}
          {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
        </div>
      </section>

      {(step === "review" || step === "done") && lines.length > 0 ? (
        <section className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Revisão por linha</h2>

          <ul className="mt-4 space-y-3">
            {lines.map((line) => (
              <li key={line.id} className="rounded-2xl border border-[var(--color-border)] bg-white p-4">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="text-xs uppercase tracking-wide text-[var(--color-text-muted)]">Entrada</p>
                    <p className="font-medium">{line.rawText}</p>
                  </div>
                  <StatusPill status={line.status.toUpperCase()} />
                </div>

                {line.suggestion ? (
                  <div className="mt-3 grid gap-3 lg:grid-cols-2">
                    <label className="block">
                      <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Tipo</span>
                      <select
                        className="oq-input"
                        value={line.editedType || line.suggestion.type}
                        onChange={(event) => {
                          setLines((current) =>
                            current.map((item) =>
                              item.id === line.id ? { ...item, editedType: event.target.value } : item,
                            ),
                          );
                        }}
                        disabled={step !== "review"}
                      >
                        <option value="task">task</option>
                        <option value="reminder">reminder</option>
                        <option value="event">event</option>
                        <option value="shopping">shopping</option>
                        <option value="routine">routine</option>
                      </select>
                    </label>

                    <label className="block">
                      <span className="mb-1 block text-xs text-[var(--color-text-muted)]">Título</span>
                      <input
                        className="oq-input"
                        value={line.editedTitle || line.suggestion.title}
                        onChange={(event) => {
                          setLines((current) =>
                            current.map((item) =>
                              item.id === line.id ? { ...item, editedTitle: event.target.value } : item,
                            ),
                          );
                        }}
                        disabled={step !== "review"}
                      />
                    </label>
                  </div>
                ) : null}

                {step === "review" ? (
                  <label className="mt-3 inline-flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={line.selected}
                      onChange={(event) => {
                        setLines((current) =>
                          current.map((item) =>
                            item.id === line.id ? { ...item, selected: event.target.checked } : item,
                          ),
                        );
                      }}
                    />
                    Confirmar esta linha
                  </label>
                ) : null}

                {step === "done" && line.confirmResult ? (
                  <div className="mt-3 flex flex-wrap items-center gap-2">
                    <button type="button" className="oq-button oq-button-ghost" onClick={() => void removeCreated(line)}>
                      Excluir item criado
                    </button>
                  </div>
                ) : null}

                {line.error ? <p className="mt-3 text-sm text-[var(--color-danger-600)]">{line.error}</p> : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {step === "done" ? (
        <section className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Resultado</h2>
          <div className="mt-4 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Confirmados</p>
              <p className="text-xl font-semibold">{stats.confirmed}/{stats.total}</p>
            </article>
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Tasks</p>
              <p className="text-xl font-semibold">{stats.tasks}</p>
            </article>
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Reminders</p>
              <p className="text-xl font-semibold">{stats.reminders}</p>
            </article>
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Events</p>
              <p className="text-xl font-semibold">{stats.events}</p>
            </article>
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Shopping</p>
              <p className="text-xl font-semibold">{stats.shopping}</p>
            </article>
            <article className="rounded-xl border border-[var(--color-border)] bg-white p-3">
              <p className="text-xs text-[var(--color-text-muted)]">Routines</p>
              <p className="text-xl font-semibold">{stats.routines}</p>
            </article>
          </div>
        </section>
      ) : null}
    </div>
  );
}
