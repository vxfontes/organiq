"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { useSession } from "@/shared/auth/session";
import type {
  CursorListResponse,
  ShoppingItemResponse,
  ShoppingListResponse,
} from "@/shared/types/api";
import { Spinner } from "@/shared/ui/spinner";

export function ShoppingBoard() {
  const { token } = useSession();

  const [lists, setLists] = useState<ShoppingListResponse[]>([]);
  const [selectedListId, setSelectedListId] = useState<string>("");
  const [items, setItems] = useState<ShoppingItemResponse[]>([]);

  const [newListTitle, setNewListTitle] = useState("");
  const [newItemTitle, setNewItemTitle] = useState("");
  const [newItemQuantity, setNewItemQuantity] = useState("");

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const selectedList = useMemo(
    () => lists.find((item) => item.id === selectedListId) || null,
    [lists, selectedListId],
  );

  const pendingItems = useMemo(() => items.filter((item) => !item.checked).length, [items]);

  const loadLists = useCallback(async () => {
    if (!token) return;

    const response = await httpClient.get<CursorListResponse<ShoppingListResponse>>("/shopping-lists", { token });
    const loadedLists = response.items || [];
    setLists(loadedLists);

    if (!selectedListId && loadedLists.length > 0) {
      setSelectedListId(loadedLists[0].id);
    }

    if (selectedListId && !loadedLists.some((item) => item.id === selectedListId)) {
      setSelectedListId(loadedLists[0]?.id || "");
    }
  }, [selectedListId, token]);

  const loadItems = useCallback(
    async (listId: string) => {
      if (!token || !listId) {
        setItems([]);
        return;
      }

      const response = await httpClient.get<CursorListResponse<ShoppingItemResponse>>(`/shopping-lists/${listId}/items`, {
        token,
      });
      setItems(response.items || []);
    },
    [token],
  );

  const loadAll = useCallback(async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      await loadLists();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível carregar listas de compras.");
      }
    } finally {
      setLoading(false);
    }
  }, [loadLists, token]);

  useEffect(() => {
    void loadAll();
  }, [loadAll]);

  useEffect(() => {
    if (!selectedListId) {
      setItems([]);
      return;
    }

    const run = async () => {
      try {
        await loadItems(selectedListId);
      } catch (requestError) {
        if (requestError instanceof ApiClientError) {
          setError(mapErrorCode(requestError.code || requestError.message));
        } else {
          setError("Não foi possível carregar itens da lista.");
        }
      }
    };

    void run();
  }, [loadItems, selectedListId]);

  const createList = async () => {
    if (!token || saving) return;
    if (!newListTitle.trim()) {
      setError("Informe o nome da lista.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      await httpClient.post<ShoppingListResponse>("/shopping-lists", {
        token,
        body: {
          title: newListTitle.trim(),
        },
      });
      setNewListTitle("");
      await loadAll();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar lista.");
      }
    } finally {
      setSaving(false);
    }
  };

  const createItem = async () => {
    if (!token || saving || !selectedListId) return;
    if (!newItemTitle.trim()) {
      setError("Informe o nome do item.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      await httpClient.post<ShoppingItemResponse>(`/shopping-lists/${selectedListId}/items`, {
        token,
        body: {
          title: newItemTitle.trim(),
          quantity: newItemQuantity.trim() || undefined,
        },
      });

      setNewItemTitle("");
      setNewItemQuantity("");
      await loadItems(selectedListId);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível criar item.");
      }
    } finally {
      setSaving(false);
    }
  };

  const toggleItem = async (item: ShoppingItemResponse) => {
    if (!token || !selectedListId) return;

    try {
      await httpClient.patch(`/shopping-items/${item.id}`, {
        token,
        body: { checked: !item.checked },
      });

      const refreshed = await httpClient.get<CursorListResponse<ShoppingItemResponse>>(`/shopping-lists/${selectedListId}/items`, {
        token,
      });
      const refreshedItems = refreshed.items || [];
      setItems(refreshedItems);

      const allChecked = refreshedItems.length > 0 && refreshedItems.every((entry) => entry.checked);
      const targetStatus = allChecked ? "DONE" : "OPEN";
      if (selectedList && selectedList.status !== targetStatus) {
        await httpClient.patch(`/shopping-lists/${selectedList.id}`, {
          token,
          body: { status: targetStatus },
        });
        await loadLists();
      }
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível atualizar item.");
      }
    }
  };

  const deleteItem = async (id: string) => {
    if (!token || !selectedListId) return;
    try {
      await httpClient.delete(`/shopping-items/${id}`, { token });
      await loadItems(selectedListId);
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir item.");
      }
    }
  };

  const deleteList = async (id: string) => {
    if (!token) return;
    try {
      await httpClient.delete(`/shopping-lists/${id}`, { token });
      if (id === selectedListId) {
        setSelectedListId("");
      }
      await loadAll();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(mapErrorCode(requestError.code || requestError.message));
      } else {
        setError("Não foi possível excluir lista.");
      }
    }
  };

  if (loading) {
    return (
      <section className="oq-card p-8">
        <Spinner label="Carregando compras" />
      </section>
    );
  }

  return (
    <div className="space-y-6">
      <section className="oq-card p-6">
        <h1 className="text-2xl font-semibold tracking-tight">Compras</h1>
        <p className="mt-2 text-sm text-[var(--color-text-muted)]">Gerencie listas abertas e marque os itens em tempo real.</p>

        <div className="mt-4 flex flex-wrap gap-2">
          <input
            className="oq-input max-w-md"
            placeholder="Nova lista de compras"
            value={newListTitle}
            onChange={(event) => setNewListTitle(event.target.value)}
          />
          <button type="button" className="oq-button oq-button-primary" onClick={() => void createList()} disabled={saving}>
            Criar lista
          </button>
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-[320px_1fr]">
        <aside className="oq-card p-4">
          <h2 className="text-lg font-semibold">Listas</h2>
          <ul className="mt-3 space-y-2">
            {lists.map((list) => (
              <li key={list.id}>
                <button
                  type="button"
                  className={
                    selectedListId === list.id
                      ? "w-full rounded-xl border border-[var(--color-primary-600)] bg-[var(--color-primary-100)] px-3 py-2 text-left"
                      : "w-full rounded-xl border border-[var(--color-border)] bg-white px-3 py-2 text-left"
                  }
                  onClick={() => setSelectedListId(list.id)}
                >
                  <p className="font-medium">{list.title}</p>
                  <p className="text-xs text-[var(--color-text-muted)]">{list.status}</p>
                </button>
              </li>
            ))}

            {lists.length === 0 ? (
              <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-3 text-sm text-[var(--color-text-muted)]">
                Nenhuma lista criada.
              </li>
            ) : null}
          </ul>
        </aside>

        <article className="oq-card p-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="text-xl font-semibold tracking-tight">{selectedList?.title || "Selecione uma lista"}</h2>
              <p className="text-sm text-[var(--color-text-muted)]">Pendentes: {pendingItems}</p>
            </div>
            {selectedList ? (
              <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteList(selectedList.id)}>
                Excluir lista
              </button>
            ) : null}
          </div>

          {selectedList ? (
            <>
              <div className="mt-4 grid gap-2 sm:grid-cols-[1fr_160px_auto]">
                <input
                  className="oq-input"
                  placeholder="Novo item"
                  value={newItemTitle}
                  onChange={(event) => setNewItemTitle(event.target.value)}
                />
                <input
                  className="oq-input"
                  placeholder="Qtd (opcional)"
                  value={newItemQuantity}
                  onChange={(event) => setNewItemQuantity(event.target.value)}
                />
                <button type="button" className="oq-button oq-button-primary" onClick={() => void createItem()} disabled={saving}>
                  Adicionar
                </button>
              </div>

              <ul className="mt-4 space-y-2">
                {items.map((item) => (
                  <li key={item.id} className="rounded-xl border border-[var(--color-border)] bg-white p-3">
                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <label className="flex items-center gap-3">
                        <input type="checkbox" checked={item.checked} onChange={() => void toggleItem(item)} />
                        <span className={item.checked ? "line-through text-[var(--color-text-muted)]" : ""}>
                          {item.title}
                          {item.quantity ? ` (${item.quantity})` : ""}
                        </span>
                      </label>
                      <button type="button" className="oq-button oq-button-ghost" onClick={() => void deleteItem(item.id)}>
                        Excluir
                      </button>
                    </div>
                  </li>
                ))}

                {items.length === 0 ? (
                  <li className="rounded-xl border border-dashed border-[var(--color-border-strong)] bg-[var(--color-surface-soft)] p-3 text-sm text-[var(--color-text-muted)]">
                    Nenhum item nesta lista.
                  </li>
                ) : null}
              </ul>
            </>
          ) : (
            <p className="mt-6 text-sm text-[var(--color-text-muted)]">Escolha ou crie uma lista para ver os itens.</p>
          )}

          {error ? <p className="mt-4 text-sm text-[var(--color-danger-600)]">{error}</p> : null}
        </article>
      </section>
    </div>
  );
}
