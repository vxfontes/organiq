"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";

import { ApiClientError, httpClient } from "@/shared/api/http-client";
import { mapErrorCode } from "@/shared/api/error-mapper";
import { tokenStore } from "@/shared/auth/token-store";
import type { AuthResponse, AuthUser } from "@/shared/types/api";

type SignupInput = {
  displayName: string;
  email: string;
  password: string;
};

type LoginInput = {
  email: string;
  password: string;
};

type SessionContextValue = {
  token: string | null;
  user: AuthUser | null;
  isAuthenticated: boolean;
  isBootstrapped: boolean;
  isBootstrapping: boolean;
  error: string | null;
  bootstrap: (force?: boolean) => Promise<boolean>;
  login: (input: LoginInput) => Promise<boolean>;
  signup: (input: SignupInput) => Promise<boolean>;
  refreshProfile: () => Promise<boolean>;
  logout: () => void;
  clearError: () => void;
};

const SessionContext = createContext<SessionContextValue | undefined>(undefined);

function getDeviceLocale(): string {
  if (typeof navigator !== "undefined" && navigator.language) {
    return navigator.language;
  }
  return "pt-BR";
}

function getDeviceTimezone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
}

function toFriendlyError(error: unknown, fallback: string): string {
  if (error instanceof ApiClientError) {
    return mapErrorCode(error.code || error.message) || fallback;
  }
  return fallback;
}

export function SessionProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isBootstrapping, setIsBootstrapping] = useState(false);
  const [isBootstrapped, setIsBootstrapped] = useState(false);

  const bootstrapInFlight = useRef(false);

  const logout = useCallback(() => {
    tokenStore.clear();
    setToken(null);
    setUser(null);
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const refreshProfile = useCallback(async (): Promise<boolean> => {
    const storedToken = tokenStore.read();
    if (!storedToken) {
      setUser(null);
      setToken(null);
      return false;
    }

    try {
      const response = await httpClient.get<AuthResponse>("/me", {
        token: storedToken,
      });
      setToken(storedToken);
      setUser(response.user);
      return true;
    } catch (requestError) {
      logout();
      setError(toFriendlyError(requestError, "Sessão expirada. Faça login novamente."));
      return false;
    }
  }, [logout]);

  const bootstrap = useCallback(
    async (force = false): Promise<boolean> => {
      if (!force && isBootstrapped) {
        return Boolean(tokenStore.read());
      }
      if (bootstrapInFlight.current) {
        return Boolean(tokenStore.read());
      }

      bootstrapInFlight.current = true;
      setIsBootstrapping(true);
      setError(null);

      try {
        await httpClient.get<{ status: string }>("/healthz", { timeoutMs: 5000 });

        const storedToken = tokenStore.read();
        if (!storedToken) {
          setToken(null);
          setUser(null);
          return false;
        }

        const me = await httpClient.get<AuthResponse>("/me", {
          token: storedToken,
        });
        setToken(storedToken);
        setUser(me.user);
        return true;
      } catch (requestError) {
        const shouldClearSession =
          requestError instanceof ApiClientError &&
          ["invalid_token", "invalid_auth_header", "missing_sub", "unauthorized"].includes(
            requestError.code || "",
          );

        if (shouldClearSession) {
          logout();
        }

        setError(toFriendlyError(requestError, "Não foi possível conectar ao servidor."));
        return false;
      } finally {
        setIsBootstrapping(false);
        setIsBootstrapped(true);
        bootstrapInFlight.current = false;
      }
    },
    [isBootstrapped, logout],
  );

  useEffect(() => {
    const storedToken = tokenStore.read();
    if (storedToken) {
      setToken(storedToken);
    }
  }, []);

  const login = useCallback(async (input: LoginInput): Promise<boolean> => {
    setError(null);
    try {
      const response = await httpClient.post<AuthResponse>("/auth/login", {
        body: input,
      });

      if (!response.token) {
        throw new ApiClientError("invalid_token", { code: "invalid_token" });
      }

      tokenStore.write(response.token);
      setToken(response.token);
      setUser(response.user);
      return true;
    } catch (requestError) {
      setError(toFriendlyError(requestError, "Não foi possível entrar agora."));
      return false;
    }
  }, []);

  const signup = useCallback(async (input: SignupInput): Promise<boolean> => {
    setError(null);
    try {
      const response = await httpClient.post<AuthResponse>("/auth/signup", {
        body: {
          ...input,
          locale: getDeviceLocale(),
          timezone: getDeviceTimezone(),
        },
      });

      if (!response.token) {
        throw new ApiClientError("invalid_token", { code: "invalid_token" });
      }

      tokenStore.write(response.token);
      setToken(response.token);
      setUser(response.user);
      return true;
    } catch (requestError) {
      setError(toFriendlyError(requestError, "Não foi possível criar a conta agora."));
      return false;
    }
  }, []);

  const value = useMemo<SessionContextValue>(
    () => ({
      token,
      user,
      isAuthenticated: Boolean(token && user),
      isBootstrapped,
      isBootstrapping,
      error,
      bootstrap,
      login,
      signup,
      refreshProfile,
      logout,
      clearError,
    }),
    [bootstrap, clearError, error, isBootstrapped, isBootstrapping, login, logout, refreshProfile, signup, token, user],
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): SessionContextValue {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error("useSession must be used within SessionProvider");
  }
  return context;
}
