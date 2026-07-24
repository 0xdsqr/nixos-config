import { composeSignal, readLimitedBody } from "../network.ts";
import { type SearchDepth, WEB_TOOLS_SETTINGS } from "../settings.ts";
import { encodeExaRequest, parseExaResponse } from "./exa-protocol.ts";
import {
  formatSearchResults,
  isExplicitNoResults,
  parseSearchResults,
  type SearchResult,
} from "./exa-results.ts";

export interface SearchResponse {
  count: number;
  results: SearchResult[];
  text: string;
}

export async function searchExa(
  query: string,
  maxResults: number,
  depth: SearchDepth,
  signal?: AbortSignal,
): Promise<SearchResponse> {
  const operation = composeSignal(signal, WEB_TOOLS_SETTINGS.search.timeoutSeconds);
  let response: Response;
  try {
    response = await fetch(WEB_TOOLS_SETTINGS.search.endpoint, {
      method: "POST",
      headers: {
        accept: "application/json, text/event-stream",
        "content-type": "application/json",
        "user-agent": "pi-web-tools/0.2 (+https://pi.dev)",
      },
      body: JSON.stringify(encodeExaRequest(query, maxResults, depth)),
      signal: operation.signal,
    });
  } catch (error) {
    operation.cleanup();
    if (operation.signal.aborted) {
      throw new Error(
        signal?.aborted
          ? "Web search cancelled"
          : `Web search timed out after ${WEB_TOOLS_SETTINGS.search.timeoutSeconds}s`,
      );
    }
    throw new Error(`Web search failed: ${error instanceof Error ? error.message : "unknown error"}`);
  }

  try {
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error(`Web search failed with HTTP ${response.status}`);
    }

    const body = new TextDecoder().decode(
      await readLimitedBody(response, WEB_TOOLS_SETTINGS.search.maxResponseBytes),
    );
    const messages = parseExaResponse(body, response.headers.get("content-type") ?? "");
    const providerError = messages.find((message) => message.kind === "error");
    if (providerError?.kind === "error") throw new Error(providerError.message);

    const providerText = messages
      .filter((message) => message.kind === "text")
      .map((message) => message.text)
      .join("\n\n")
      .trim();
    const results = parseSearchResults(providerText).slice(0, maxResults);
    if (!results.length && !isExplicitNoResults(providerText)) {
      throw new Error("Search provider returned an unrecognized result format");
    }
    return {
      count: results.length,
      results,
      text: formatSearchResults(query, results),
    };
  } catch (error) {
    if (operation.signal.aborted) {
      throw new Error(
        signal?.aborted
          ? "Web search cancelled"
          : `Web search timed out after ${WEB_TOOLS_SETTINGS.search.timeoutSeconds}s`,
      );
    }
    if (error instanceof Error && /^(?:Response exceeds|Search provider|Web search)/.test(error.message)) throw error;
    throw new Error("Web search failed while reading the provider response");
  } finally {
    operation.cleanup();
  }
}
