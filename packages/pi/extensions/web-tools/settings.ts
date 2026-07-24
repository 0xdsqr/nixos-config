export const FETCH_FORMATS = ["markdown", "text", "html"] as const;
export const SEARCH_DEPTHS = ["auto", "fast", "deep"] as const;

export type FetchFormat = (typeof FETCH_FORMATS)[number];
export type SearchDepth = (typeof SEARCH_DEPTHS)[number];

export const WEB_TOOLS_SETTINGS = {
  fetch: {
    timeoutSeconds: 30,
    maxResponseBytes: 5 * 1024 * 1024,
    maxRedirects: 5,
    defaultFormat: "markdown" as FetchFormat,
    browserUserAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
      + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
    fallbackUserAgent: "opencode",
  },
  search: {
    endpoint: "https://mcp.exa.ai/mcp",
    timeoutSeconds: 25,
    defaultMaxResults: 8,
    maximumResults: 20,
    defaultDepth: "auto" as SearchDepth,
    maxResponseBytes: 1024 * 1024,
    snippetCharacters: 280,
  },
} as const;

export function clampInteger(
  value: number | undefined,
  fallback: number,
  minimum: number,
  maximum: number,
): number {
  if (!Number.isFinite(value)) return fallback;
  return Math.max(minimum, Math.min(maximum, Math.round(value!)));
}
