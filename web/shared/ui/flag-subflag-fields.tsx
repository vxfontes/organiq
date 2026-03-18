"use client";

import { useEffect, useMemo, useState } from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import type { CursorListResponse, FlagResponse, SubflagResponse } from "@/shared/types/api";

type Props = {
  token: string | null;
  flagId?: string;
  subflagId?: string;
  onChange: (value: { flagId?: string; subflagId?: string }) => void;
};

export function FlagSubflagFields({ token, flagId, subflagId, onChange }: Props) {
  const [flags, setFlags] = useState<FlagResponse[]>([]);
  const [subflags, setSubflags] = useState<SubflagResponse[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let mounted = true;

    const load = async () => {
      try {
        const response = await httpClient.get<CursorListResponse<FlagResponse>>("/flags", { token });
        if (!mounted) return;
        setFlags(response.items || []);
      } catch (requestError) {
        if (!mounted) return;
        if (requestError instanceof ApiClientError) {
          setError(mapErrorCode(requestError.code || requestError.message));
        } else {
          setError("Não foi possível carregar os contextos.");
        }
      }
    };

    void load();

    return () => {
      mounted = false;
    };
  }, [token]);

  useEffect(() => {
    if (!token || !flagId) {
      setSubflags([]);
      return;
    }

    let mounted = true;

    const load = async () => {
      try {
        const response = await httpClient.get<CursorListResponse<SubflagResponse>>(`/flags/${flagId}/subflags`, {
          token,
        });
        if (!mounted) return;
        setSubflags(response.items || []);
      } catch (requestError) {
        if (!mounted) return;
        if (requestError instanceof ApiClientError) {
          setError(mapErrorCode(requestError.code || requestError.message));
        } else {
          setError("Não foi possível carregar os subcontextos.");
        }
      }
    };

    void load();

    return () => {
      mounted = false;
    };
  }, [flagId, token]);

  const hasSubflags = useMemo(() => subflags.length > 0, [subflags.length]);

  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <label className="block">
        <span className="mb-2 block text-xs font-semibold uppercase tracking-wide text-[var(--color-text-muted)]">Flag</span>
        <select
          className="oq-input"
          value={flagId || ""}
          onChange={(event) => {
            const selectedFlag = event.target.value;
            onChange({ flagId: selectedFlag || undefined, subflagId: undefined });
          }}
        >
          <option value="">Sem flag</option>
          {flags.map((flag) => (
            <option key={flag.id} value={flag.id}>
              {flag.name}
            </option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="mb-2 block text-xs font-semibold uppercase tracking-wide text-[var(--color-text-muted)]">Subflag</span>
        <select
          className="oq-input"
          value={subflagId || ""}
          onChange={(event) => {
            onChange({ flagId: flagId || undefined, subflagId: event.target.value || undefined });
          }}
          disabled={!hasSubflags}
        >
          <option value="">Sem subflag</option>
          {subflags.map((subflag) => (
            <option key={subflag.id} value={subflag.id}>
              {subflag.name}
            </option>
          ))}
        </select>
      </label>

      {error ? <p className="sm:col-span-2 text-xs text-[var(--color-danger-600)]">{error}</p> : null}
    </div>
  );
}
