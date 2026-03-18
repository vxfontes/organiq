"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type { CursorListResponse, FlagResponse, SubflagResponse } from "@/shared/types/api";
import { Spinner } from "@/shared/ui/spinner";

const contextColors = [
  "#0F766E",
  "#0D9488",
  "#14B8A6",
  "#99F6E4",
  "#4F46E5",
  "#F59E0B",
  "#DC2626",
  "#16A34A",
];

type NullableString = string | null;

export function ContextsManager() {
  const { token } = useSession();

  const [flags, setFlags] = useState<FlagResponse[]>([]);
  const [subflags, setSubflags] = useState<SubflagResponse[]>([]);
  const [selectedFlagId, setSelectedFlagId] = useState<string>("");

  const [newFlagName, setNewFlagName] = useState("");
  const [newFlagColor, setNewFlagColor] = useState("#0F766E");
  const [newSubflagName, setNewSubflagName] = useState("");

  const [editingFlagId, setEditingFlagId] = useState<string | null>(null);
  const [editingFlagName, setEditingFlagName] = useState("");
  const [editingFlagColor, setEditingFlagColor] = useState("");

  const [editingSubflagId, setEditingSubflagId] = useState<string | null>(null);
  const [editingSubflagName, setEditingSubflagName] = useState("");

  const [loadingFlags, setLoadingFlags] = useState(true);
  const [loadingSubflags, setLoadingSubflags] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<NullableString>(null);
  const [message, setMessage] = useState<NullableString>(null);

  const selectedFlag = useMemo(
    () => flags.find((item) => item.id === selectedFlagId) || null,
    [flags, selectedFlagId],
  );

  const onApiError = (requestError: unknown, fallbackMessage: string) => {
    if (requestError instanceof ApiClientError) {
      setError(mapErrorCode(requestError.code || requestError.message));
      return;
    }
    setError(fallbackMessage);
  };

  const loadFlags = useCallback(
    async (preferredFlagId?: string) => {
      if (!token) return;

      const response = await httpClient.get<CursorListResponse<FlagResponse>>("/flags", { token });
      const loadedFlags = response.items || [];
      setFlags(loadedFlags);

      if (loadedFlags.length === 0) {
        setSelectedFlagId("");
        return;
      }

      const expectedId = preferredFlagId || selectedFlagId;
      if (expectedId && loadedFlags.some((item) => item.id === expectedId)) {
        setSelectedFlagId(expectedId);
        return;
      }

      setSelectedFlagId(loadedFlags[0].id);
    },
    [selectedFlagId, token],
  );

  const loadSubflags = useCallback(
    async (flagId: string) => {
      if (!token || !flagId) {
        setSubflags([]);
        return;
      }

      const response = await httpClient.get<CursorListResponse<SubflagResponse>>(`/flags/${flagId}/subflags`, {
        token,
      });
      setSubflags(response.items || []);
    },
    [token],
  );

  useEffect(() => {
    if (!token) return;
    let mounted = true;

    const run = async () => {
      setLoadingFlags(true);
      setError(null);
      try {
        await loadFlags();
      } catch (requestError) {
        if (!mounted) return;
        onApiError(requestError, "Nao foi possivel carregar os contextos.");
      } finally {
        if (mounted) {
          setLoadingFlags(false);
        }
      }
    };

    void run();

    return () => {
      mounted = false;
    };
  }, [loadFlags, token]);

  useEffect(() => {
    if (!selectedFlagId || !token) {
      setSubflags([]);
      return;
    }
    let mounted = true;

    const run = async () => {
      setLoadingSubflags(true);
      setError(null);
      try {
        await loadSubflags(selectedFlagId);
      } catch (requestError) {
        if (!mounted) return;
        onApiError(requestError, "Nao foi possivel carregar subcontextos.");
      } finally {
        if (mounted) {
          setLoadingSubflags(false);
        }
      }
    };

    void run();

    return () => {
      mounted = false;
    };
  }, [loadSubflags, selectedFlagId, token]);

  const createFlag = async () => {
    if (!token || saving) return;
    if (!newFlagName.trim()) {
      setError("Informe o nome do contexto.");
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      const createdFlag = await httpClient.post<FlagResponse>("/flags", {
        token,
        body: {
          name: newFlagName.trim(),
          color: newFlagColor || undefined,
        },
      });
      setNewFlagName("");
      await loadFlags(createdFlag.id);
      setMessage("Contexto criado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel criar contexto.");
    } finally {
      setSaving(false);
    }
  };

  const saveFlag = async () => {
    if (!token || !editingFlagId || saving) return;
    if (!editingFlagName.trim()) {
      setError("Informe o nome do contexto.");
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.patch<FlagResponse>(`/flags/${editingFlagId}`, {
        token,
        body: {
          name: editingFlagName.trim(),
          ...(editingFlagColor ? { color: editingFlagColor } : {}),
        },
      });
      setEditingFlagId(null);
      setEditingFlagName("");
      setEditingFlagColor("");
      await loadFlags(selectedFlagId);
      setMessage("Contexto atualizado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel atualizar contexto.");
    } finally {
      setSaving(false);
    }
  };

  const removeFlag = async (flag: FlagResponse) => {
    if (!token || saving) return;
    if (!window.confirm(`Excluir contexto "${flag.name}"?`)) {
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.delete(`/flags/${flag.id}`, { token });
      setEditingFlagId(null);
      setEditingFlagName("");
      setEditingFlagColor("");
      await loadFlags();
      setMessage("Contexto removido.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel excluir contexto.");
    } finally {
      setSaving(false);
    }
  };

  const createSubflag = async () => {
    if (!token || saving || !selectedFlagId) return;
    if (!newSubflagName.trim()) {
      setError("Informe o nome do subcontexto.");
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.post<SubflagResponse>(`/flags/${selectedFlagId}/subflags`, {
        token,
        body: {
          name: newSubflagName.trim(),
        },
      });
      setNewSubflagName("");
      await loadSubflags(selectedFlagId);
      setMessage("Subcontexto criado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel criar subcontexto.");
    } finally {
      setSaving(false);
    }
  };

  const saveSubflag = async () => {
    if (!token || !editingSubflagId || saving) return;
    if (!editingSubflagName.trim()) {
      setError("Informe o nome do subcontexto.");
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.patch<SubflagResponse>(`/subflags/${editingSubflagId}`, {
        token,
        body: {
          name: editingSubflagName.trim(),
        },
      });
      setEditingSubflagId(null);
      setEditingSubflagName("");
      await loadSubflags(selectedFlagId);
      setMessage("Subcontexto atualizado.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel atualizar subcontexto.");
    } finally {
      setSaving(false);
    }
  };

  const removeSubflag = async (subflag: SubflagResponse) => {
    if (!token || saving) return;
    if (!window.confirm(`Excluir subcontexto "${subflag.name}"?`)) {
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);

    try {
      await httpClient.delete(`/subflags/${subflag.id}`, { token });
      setEditingSubflagId(null);
      setEditingSubflagName("");
      await loadSubflags(selectedFlagId);
      setMessage("Subcontexto removido.");
    } catch (requestError) {
      onApiError(requestError, "Nao foi possivel excluir subcontexto.");
    } finally {
      setSaving(false);
    }
  };

  if (loadingFlags) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando contextos" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <h1 className="text-2xl font-semibold tracking-tight">Contextos</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">
          Organize suas areas com contextos e subcontextos para tarefas, lembretes e agenda.
        </p>
      </section>

      <section className="grid gap-6 lg:grid-cols-[minmax(320px,380px)_1fr]">
        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Flags</h2>

          <div className="mt-4 grid gap-3">
            <input
              className="oq-input"
              placeholder="Nome do contexto"
              value={newFlagName}
              onChange={(event) => setNewFlagName(event.target.value)}
            />

            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-muted)]">Cor</p>
              <div className="flex flex-wrap gap-2">
                {contextColors.map((color) => (
                  <button
                    key={color}
                    type="button"
                    className={
                      newFlagColor === color
                        ? "h-8 w-8 rounded-full border-2 border-[var(--color-text)]"
                        : "h-8 w-8 rounded-full border border-[var(--color-border)]"
                    }
                    style={{ backgroundColor: color }}
                    onClick={() => setNewFlagColor(color)}
                    aria-label={`Selecionar cor ${color}`}
                  />
                ))}
              </div>
            </div>

            <button type="button" className="oq-button oq-button-primary" onClick={() => void createFlag()} disabled={saving}>
              Criar contexto
            </button>
          </div>

          <ul className="mt-6 space-y-2">
            {flags.map((flag) => {
              const selected = flag.id === selectedFlagId;
              const isEditing = flag.id === editingFlagId;

              return (
                <li
                  key={flag.id}
                  className={
                    selected
                      ? "rounded-xl border border-[var(--color-primary-600)] bg-[var(--color-primary-50)] p-3"
                      : "rounded-xl border border-[var(--color-border)] bg-white p-3"
                  }
                >
                  {isEditing ? (
                    <div className="grid gap-2">
                      <input
                        className="oq-input"
                        value={editingFlagName}
                        onChange={(event) => setEditingFlagName(event.target.value)}
                      />
                      <div className="flex flex-wrap gap-2">
                        {contextColors.map((color) => (
                          <button
                            key={color}
                            type="button"
                            className={
                              editingFlagColor === color
                                ? "h-7 w-7 rounded-full border-2 border-[var(--color-text)]"
                                : "h-7 w-7 rounded-full border border-[var(--color-border)]"
                            }
                            style={{ backgroundColor: color }}
                            onClick={() => setEditingFlagColor(color)}
                            aria-label={`Editar cor ${color}`}
                          />
                        ))}
                      </div>
                      <div className="flex gap-2">
                        <button type="button" className="oq-button oq-button-secondary" onClick={() => void saveFlag()} disabled={saving}>
                          Salvar
                        </button>
                        <button
                          type="button"
                          className="oq-button oq-button-ghost"
                          onClick={() => {
                            setEditingFlagId(null);
                            setEditingFlagName("");
                            setEditingFlagColor("");
                          }}
                          disabled={saving}
                        >
                          Cancelar
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <button
                        type="button"
                        className="flex min-w-0 items-center gap-2 text-left"
                        onClick={() => setSelectedFlagId(flag.id)}
                      >
                        <span className="h-3 w-3 rounded-full border border-[var(--color-border)]" style={{ backgroundColor: flag.color || "#D1D5DB" }} />
                        <span className="truncate font-medium">{flag.name}</span>
                      </button>
                      <div className="flex gap-2">
                        <button
                          type="button"
                          className="oq-button oq-button-ghost"
                          onClick={() => {
                            setEditingFlagId(flag.id);
                            setEditingFlagName(flag.name);
                            setEditingFlagColor(flag.color || "#0F766E");
                          }}
                          disabled={saving}
                        >
                          Editar
                        </button>
                        <button type="button" className="oq-button oq-button-ghost" onClick={() => void removeFlag(flag)} disabled={saving}>
                          Excluir
                        </button>
                      </div>
                    </div>
                  )}
                </li>
              );
            })}

            {flags.length === 0 ? (
              <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                Nenhum contexto cadastrado.
              </li>
            ) : null}
          </ul>
        </article>

        <article className="oq-card p-6">
          <h2 className="text-xl font-semibold tracking-tight">Subflags</h2>
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">
            {selectedFlag ? `Contexto ativo: ${selectedFlag.name}` : "Selecione um contexto para gerenciar subcontextos."}
          </p>

          {selectedFlag ? (
            <>
              <div className="mt-4 flex flex-wrap gap-2">
                <input
                  className="oq-input max-w-md"
                  placeholder="Novo subcontexto"
                  value={newSubflagName}
                  onChange={(event) => setNewSubflagName(event.target.value)}
                />
                <button type="button" className="oq-button oq-button-primary" onClick={() => void createSubflag()} disabled={saving}>
                  Criar subcontexto
                </button>
              </div>

              {loadingSubflags ? (
                <div className="mt-6">
                  <Spinner label="Carregando subcontextos" />
                </div>
              ) : (
                <ul className="mt-6 space-y-2">
                  {subflags.map((subflag) => {
                    const isEditing = subflag.id === editingSubflagId;
                    return (
                      <li key={subflag.id} className="rounded-xl border border-[var(--color-border)] bg-white p-3">
                        {isEditing ? (
                          <div className="flex flex-wrap gap-2">
                            <input
                              className="oq-input min-w-[220px] flex-1"
                              value={editingSubflagName}
                              onChange={(event) => setEditingSubflagName(event.target.value)}
                            />
                            <button
                              type="button"
                              className="oq-button oq-button-secondary"
                              onClick={() => void saveSubflag()}
                              disabled={saving}
                            >
                              Salvar
                            </button>
                            <button
                              type="button"
                              className="oq-button oq-button-ghost"
                              onClick={() => {
                                setEditingSubflagId(null);
                                setEditingSubflagName("");
                              }}
                              disabled={saving}
                            >
                              Cancelar
                            </button>
                          </div>
                        ) : (
                          <div className="flex flex-wrap items-center justify-between gap-2">
                            <p className="font-medium">{subflag.name}</p>
                            <div className="flex gap-2">
                              <button
                                type="button"
                                className="oq-button oq-button-ghost"
                                onClick={() => {
                                  setEditingSubflagId(subflag.id);
                                  setEditingSubflagName(subflag.name);
                                }}
                                disabled={saving}
                              >
                                Editar
                              </button>
                              <button
                                type="button"
                                className="oq-button oq-button-ghost"
                                onClick={() => void removeSubflag(subflag)}
                                disabled={saving}
                              >
                                Excluir
                              </button>
                            </div>
                          </div>
                        )}
                      </li>
                    );
                  })}

                  {subflags.length === 0 ? (
                    <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
                      Nenhum subcontexto para este contexto.
                    </li>
                  ) : null}
                </ul>
              )}
            </>
          ) : (
            <div className="mt-6 rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-4 text-sm text-[var(--color-text-muted)]">
              Selecione um contexto na coluna ao lado.
            </div>
          )}
        </article>
      </section>

      {message ? <p className="text-sm text-[var(--color-success-600)]">{message}</p> : null}
      {error ? <p className="text-sm text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
