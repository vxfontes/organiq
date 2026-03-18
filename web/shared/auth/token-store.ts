const TOKEN_KEY = "organiq.auth.token";

function canUseStorage(): boolean {
  return typeof window !== "undefined" && typeof window.localStorage !== "undefined";
}

export const tokenStore = {
  read(): string | null {
    if (!canUseStorage()) return null;
    const token = window.localStorage.getItem(TOKEN_KEY);
    return token?.trim() ? token : null;
  },
  write(token: string): void {
    if (!canUseStorage()) return;
    window.localStorage.setItem(TOKEN_KEY, token);
  },
  clear(): void {
    if (!canUseStorage()) return;
    window.localStorage.removeItem(TOKEN_KEY);
  },
};
