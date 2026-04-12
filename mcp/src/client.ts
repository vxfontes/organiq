import type { AuthResponse } from './types.js';

const baseUrl = process.env.ORGANIQ_BASE_URL ?? 'http://localhost:8080';
let token: string | null = null;

export async function login(email: string, password: string): Promise<AuthResponse> {
  const res = await fetch(`${baseUrl}/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  const data = (await res.json()) as AuthResponse & { error?: string };

  if (!res.ok) {
    throw new Error(`Login failed: ${data.error ?? res.statusText}`);
  }

  token = data.token;
  return data;
}

export async function initAuth(): Promise<void> {
  if (process.env.ORGANIQ_TOKEN) {
    token = process.env.ORGANIQ_TOKEN;
    return;
  }

  const email = process.env.ORGANIQ_EMAIL;
  const password = process.env.ORGANIQ_PASSWORD;

  if (!email || !password) {
    throw new Error(
      'Authentication required: set ORGANIQ_TOKEN, or both ORGANIQ_EMAIL and ORGANIQ_PASSWORD',
    );
  }

  await login(email, password);
}

export async function apiRequest<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<T> {
  if (!token) throw new Error('Not authenticated. Call initAuth() first.');

  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (res.status === 204) return undefined as T;

  const data = (await res.json()) as T & { error?: string };

  if (!res.ok) {
    throw new Error(data.error ?? `HTTP ${res.status}`);
  }

  return data;
}
