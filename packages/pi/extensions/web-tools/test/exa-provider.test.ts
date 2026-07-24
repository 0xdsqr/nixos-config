import assert from "node:assert/strict";
import { afterEach, test } from "node:test";

import { searchExa } from "../providers/exa.ts";

const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function providerResponse(text: string, contentType = "application/json"): Response {
  return new Response(
    JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      result: { content: [{ type: "text", text }] },
    }),
    { headers: { "content-type": contentType }, status: 200 },
  );
}

test("Exa adapter sends MCP and projects normalized results", async () => {
  let requestBody = "";
  globalThis.fetch = (async (_input, init) => {
    requestBody = String(init?.body);
    return providerResponse("Title: Pi docs\nURL: https://pi.dev/docs/latest\nText: Current documentation.");
  }) as typeof fetch;

  const result = await searchExa("pi documentation", 3, "auto");
  assert.equal(result.count, 1);
  assert.equal(result.results[0]?.url, "https://pi.dev/docs/latest");
  assert.equal(
    (JSON.parse(requestBody) as { params: { arguments: { query: string } } }).params.arguments.query,
    "pi documentation",
  );
});

test("Exa adapter accepts SSE responses", async () => {
  const payload = JSON.stringify({
    result: {
      content: [{ type: "text", text: "Title: Pi\nURL: https://pi.dev/\nText: Agent." }],
    },
  });
  globalThis.fetch = (async () =>
    new Response(`data: ${payload}\n\n`, {
      headers: { "content-type": "text/event-stream" },
      status: 200,
    })) as typeof fetch;

  assert.equal((await searchExa("pi", 1, "fast")).count, 1);
});

test("Exa adapter exposes stable HTTP and protocol failures", async () => {
  globalThis.fetch = (async () => new Response("internal details", { status: 503 })) as typeof fetch;
  await assert.rejects(() => searchExa("pi", 1, "fast"), /HTTP 503/);

  globalThis.fetch = (async () =>
    new Response(JSON.stringify({ error: { message: "private upstream message" } }), {
      headers: { "content-type": "application/json" },
      status: 200,
    })) as typeof fetch;
  await assert.rejects(
    () => searchExa("pi", 1, "fast"),
    (error: Error) => error.message === "Search provider returned an error",
  );
});

test("Exa adapter enforces its response-size boundary", async () => {
  globalThis.fetch = (async () =>
    new Response("small", {
      headers: { "content-length": String(1024 * 1024 + 1) },
      status: 200,
    })) as typeof fetch;
  await assert.rejects(() => searchExa("pi", 1, "fast"), /1MB limit/);
});
