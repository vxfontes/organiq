import { env } from "@/shared/config/env";
import type { ApiErrorResponse } from "@/shared/types/api";

export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export type RequestOptions = {
  query?: Record<string, string | number | boolean | null | undefined>;
  body?: unknown;
  token?: string | null;
  timeoutMs?: number;
  headers?: Record<string, string>;
  signal?: AbortSignal;
};

export class ApiClientError extends Error {
  status?: number;
  code?: string;
  requestId?: string;
  details?: unknown;

  constructor(message: string, init: Partial<ApiClientError> = {}) {
    super(message);
    this.name = "ApiClientError";
    this.status = init.status;
    this.code = init.code;
    this.requestId = init.requestId;
    this.details = init.details;
  }
}

function buildUrl(path: string, query?: RequestOptions["query"]): string {
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  const url = new URL(`${env.apiBaseUrl}${cleanPath}`);

  if (query) {
    Object.entries(query).forEach(([key, value]) => {
      if (value === null || value === undefined || value === "") {
        return;
      }
      url.searchParams.set(key, String(value));
    });
  }

  return url.toString();
}

async function parseResponseBody(response: Response): Promise<unknown> {
  const contentType = response.headers.get("content-type") ?? "";
  if (contentType.includes("application/json")) {
    return response.json();
  }

  const text = await response.text();
  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return { message: text };
  }
}

function mergeSignals(signalA?: AbortSignal, signalB?: AbortSignal): AbortSignal | undefined {
  if (!signalA) return signalB;
  if (!signalB) return signalA;

  const controller = new AbortController();
  const onAbort = () => controller.abort();

  signalA.addEventListener("abort", onAbort, { once: true });
  signalB.addEventListener("abort", onAbort, { once: true });

  return controller.signal;
}

export async function request<T>(
  method: HttpMethod,
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const timeoutMs = options.timeoutMs ?? 12000;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(buildUrl(path, options.query), {
      method,
      signal: mergeSignals(controller.signal, options.signal),
      headers: {
        "Content-Type": "application/json",
        ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
        ...(options.headers ?? {}),
      },
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      cache: "no-store",
    });

    const responseBody = await parseResponseBody(response);

    if (!response.ok) {
      const payload = (responseBody || {}) as ApiErrorResponse;
      const code = payload.error || payload.message;
      throw new ApiClientError(code || "request_failed", {
        status: response.status,
        code,
        requestId: response.headers.get(env.requestIdHeader) || payload.requestId,
        details: payload,
      });
    }

    return responseBody as T;
  } catch (error) {
    if (error instanceof ApiClientError) {
      throw error;
    }

    if (error instanceof DOMException && error.name === "AbortError") {
      throw new ApiClientError("timeout", { code: "timeout" });
    }

    throw new ApiClientError("connection_refused", {
      code: "connection_refused",
      details: error,
    });
  } finally {
    clearTimeout(timeout);
  }
}

export const httpClient = {
  get: <T>(path: string, options?: RequestOptions) => request<T>("GET", path, options),
  post: <T>(path: string, options?: RequestOptions) => request<T>("POST", path, options),
  put: <T>(path: string, options?: RequestOptions) => request<T>("PUT", path, options),
  patch: <T>(path: string, options?: RequestOptions) => request<T>("PATCH", path, options),
  delete: <T>(path: string, options?: RequestOptions) => request<T>("DELETE", path, options),
};
