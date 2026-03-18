export function parseNumberList(input: string): number[] {
  return input
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => Number(item))
    .filter((value) => Number.isFinite(value))
    .map((value) => Math.trunc(value));
}

export function safeString(value: string): string | undefined {
  const normalized = value.trim();
  return normalized ? normalized : undefined;
}
