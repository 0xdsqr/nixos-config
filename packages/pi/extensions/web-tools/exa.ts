import { parsePublicUrl, readLimitedBody } from "./network.ts";

const EXA_ENDPOINT = "https://mcp.exa.ai/mcp";
const MAX_SEARCH_BYTES = 1024 * 1024;

export type SearchDepth = "auto" | "fast";

export interface SearchResult {
  published?: string;
  snippet?: string;
  source?: string;
  title: string;
  url: string;
}

function mcpRequest(query: string, maxResults: number, depth: SearchDepth): object {
  return {
    jsonrpc: "2.0",
    id: 1,
    method: "tools/call",
    params: {
      name: "web_search_exa",
      arguments: {
        query,
        type: depth,
        numResults: maxResults,
        livecrawl: "fallback",
        contextMaxCharacters: 2_000,
      },
    },
  };
}

function parsePayload(payload: unknown): string[] {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return [];
  const record = payload as Record<string, unknown>;
  if (record.error) throw new Error("Search provider returned an error");
  if (!record.result || typeof record.result !== "object" || Array.isArray(record.result)) return [];

  const result = record.result as Record<string, unknown>;
  if (result.isError === true) throw new Error("Search provider returned an error");
  if (!Array.isArray(result.content)) return [];

  return result.content.flatMap((item) => {
    if (!item || typeof item !== "object" || Array.isArray(item)) return [];
    const content = item as Record<string, unknown>;
    return content.type === "text" && typeof content.text === "string" ? [content.text] : [];
  });
}

function parseMcpResponse(body: string, responseType: string): string {
  const payloads: unknown[] = [];
  if (responseType.toLowerCase().includes("text/event-stream") || /^data:/m.test(body)) {
    const events = body.replace(/\r\n/g, "\n").split(/\n\n+/);
    for (const event of events) {
      const data = event
        .split("\n")
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).trim())
        .join("\n");
      if (!data || data === "[DONE]") continue;
      try {
        payloads.push(JSON.parse(data));
      } catch {
        continue;
      }
    }
  } else {
    try {
      payloads.push(JSON.parse(body));
    } catch {
      throw new Error("Search provider returned invalid JSON");
    }
  }

  const text = payloads.flatMap(parsePayload).join("\n\n").trim();
  if (!text) throw new Error("Search provider returned no readable results");
  return text;
}

function cleanMetadata(value: string | undefined): string | undefined {
  const cleaned = value?.trim();
  if (!cleaned || /^(n\/a|none|null|unknown)$/i.test(cleaned)) return undefined;
  return cleaned;
}

export function parseSearchResults(input: string): SearchResult[] {
  const starts = [...input.matchAll(/^Title:\s*/gm)].map((match) => match.index ?? 0);
  if (starts.length === 0) return [];

  return starts.flatMap((start, index) => {
    const section = input.slice(start, starts[index + 1] ?? input.length);
    const title = section.match(/^Title:\s*(.+)$/m)?.[1]?.trim() ?? "";
    const rawUrl = section.match(/^URL:\s*(.+)$/m)?.[1]?.trim() ?? "";
    if (!rawUrl) return [];

    let url: string;
    try {
      url = parsePublicUrl(rawUrl).href;
    } catch {
      return [];
    }

    const textStart = section.search(/^(Text|Highlights):\s*/m);
    const snippet = textStart >= 0
      ? section.slice(textStart).replace(/^(Text|Highlights):\s*/m, "").replace(/\n\.{3}\n/g, "\n").trim()
      : undefined;

    return [{
      title: title || url,
      url,
      published: cleanMetadata(
        section.match(/^Published(?: Date)?:\s*(.+)$/m)?.[1],
      ),
      source: cleanMetadata(
        section.match(/^(?:Source|Author):\s*(.+)$/m)?.[1],
      ),
      snippet: snippet ? snippet.slice(0, 2_000).trim() : undefined,
    }];
  });
}

export function formatSearchResults(query: string, results: readonly SearchResult[]): string {
  if (results.length === 0) return `No results found for: ${query}`;

  const lines = [`Search results for: ${query}`];
  results.forEach((result, index) => {
    lines.push("", `${index + 1}. ${result.title}`, `   URL: ${result.url}`);
    if (result.published) lines.push(`   Published: ${result.published}`);
    if (result.source) lines.push(`   Source: ${result.source}`);
    if (result.snippet) lines.push(`   ${result.snippet.replace(/\n+/g, "\n   ")}`);
  });
  return lines.join("\n");
}

export async function searchExa(
  query: string,
  maxResults: number,
  depth: SearchDepth,
  signal?: AbortSignal,
): Promise<{ count: number; text: string }> {
  let response: Response;
  try {
    response = await fetch(EXA_ENDPOINT, {
      method: "POST",
      headers: {
        accept: "application/json, text/event-stream",
        "content-type": "application/json",
        "user-agent": "pi-web-tools/0.1 (+https://pi.dev)",
      },
      body: JSON.stringify(mcpRequest(query, maxResults, depth)),
      signal,
    });
  } catch (error) {
    if (signal?.aborted) throw new Error("Web search cancelled");
    throw new Error(`Web search failed: ${error instanceof Error ? error.message : "unknown error"}`);
  }

  if (!response.ok) {
    await response.body?.cancel();
    throw new Error(`Web search failed with HTTP ${response.status}`);
  }

  const body = new TextDecoder().decode(await readLimitedBody(response, MAX_SEARCH_BYTES));
  const providerText = parseMcpResponse(body, response.headers.get("content-type") ?? "");
  const results = parseSearchResults(providerText).slice(0, maxResults);
  return {
    count: results.length,
    text: results.length > 0 ? formatSearchResults(query, results) : providerText,
  };
}
