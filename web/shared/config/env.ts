const DEFAULT_API_HOST = "https://inbota-api.onrender.com";

function normalizeHost(host: string): string {
  return host.replace(/\/+$/, "");
}

export const env = {
  apiHost: normalizeHost(process.env.NEXT_PUBLIC_API_HOST?.trim() || DEFAULT_API_HOST),
  apiBaseUrl: `${normalizeHost(process.env.NEXT_PUBLIC_API_HOST?.trim() || DEFAULT_API_HOST)}/v1`,
  requestIdHeader: "X-Request-Id",
};
