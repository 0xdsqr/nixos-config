import type { SearchDepth } from "../settings.ts";

export type ExaMessage =
  | { kind: "text"; text: string }
  | { kind: "error"; message: string };

export function encodeExaRequest(query: string, maxResults: number, depth: SearchDepth): object {
  return {
    jsonrpc: "2.0",
    id: 1,
    method: "tools/call",
    params: {
      name: "web_search_exa",
      arguments: {
        query,
        type: depth === "deep" ? "fast" : depth,
        numResults: maxResults,
        livecrawl: "fallback",
        contextMaxCharacters: 2_000,
      },
    },
  };
}

function record(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parsePayload(payload: unknown): ExaMessage[] {
  if (!record(payload)) throw new Error("Search provider returned an invalid MCP payload");
  if (record(payload.error)) return [{ kind: "error", message: "Search provider returned an error" }];
  if (!record(payload.result)) throw new Error("Search provider response is missing its result");
  if (payload.result.isError === true) return [{ kind: "error", message: "Search provider returned an error" }];
  if (!Array.isArray(payload.result.content)) {
    throw new Error("Search provider response is missing result content");
  }
  return payload.result.content.flatMap((item) => {
    if (!record(item) || item.type !== "text" || typeof item.text !== "string") return [];
    const text = item.text.trim();
    return text ? [{ kind: "text" as const, text }] : [];
  });
}

export function parseSseData(input: string): string[] {
  const chunks: string[] = [];
  let current: string[] = [];
  for (const line of input.replace(/\r\n/g, "\n").split("\n")) {
    if (line.startsWith("data:")) {
      current.push(line.slice(5).trim());
    } else if (!line.trim() && current.length) {
      chunks.push(current.join("\n"));
      current = [];
    }
  }
  if (current.length) chunks.push(current.join("\n"));
  return chunks.filter((chunk) => chunk && chunk !== "[DONE]");
}

export function parseExaResponse(body: string, contentType: string): ExaMessage[] {
  const serialized = contentType.toLowerCase().includes("text/event-stream") || /^data:/m.test(body)
    ? parseSseData(body)
    : [body];
  const messages: ExaMessage[] = [];
  let invalidJson = false;

  for (const item of serialized) {
    try {
      messages.push(...parsePayload(JSON.parse(item)));
    } catch (error) {
      if (error instanceof SyntaxError) invalidJson = true;
      else throw error;
    }
  }

  if (messages.length) return messages;
  if (invalidJson) throw new Error("Search provider returned invalid JSON");
  throw new Error("Search provider returned no MCP messages");
}
