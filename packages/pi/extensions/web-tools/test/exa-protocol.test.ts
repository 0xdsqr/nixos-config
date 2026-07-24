import assert from "node:assert/strict";
import test from "node:test";

import {
  encodeExaRequest,
  parseExaResponse,
  parseSseData,
} from "../providers/exa-protocol.ts";

test("deep remains compatible while using Exa's supported fast protocol mode", () => {
  const request = encodeExaRequest("pi docs", 12, "deep") as {
    params: { arguments: { numResults: number; type: string } };
  };
  assert.equal(request.params.arguments.type, "fast");
  assert.equal(request.params.arguments.numResults, 12);
});

test("SSE parser combines data lines and ignores DONE", () => {
  assert.deepEqual(parseSseData("data: {\"one\":\ndata: 1}\n\ndata: [DONE]\n\n"), ['{"one":\n1}']);
});

test("MCP parser extracts text and safely collapses provider errors", () => {
  assert.deepEqual(
    parseExaResponse(
      JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        result: { content: [{ type: "text", text: "  result  " }] },
      }),
      "application/json",
    ),
    [{ kind: "text", text: "result" }],
  );
  assert.deepEqual(
    parseExaResponse(JSON.stringify({ error: { message: "internal provider secret" } }), "application/json"),
    [{ kind: "error", message: "Search provider returned an error" }],
  );
});

test("MCP parser rejects malformed and empty payloads", () => {
  assert.throws(() => parseExaResponse("not json", "application/json"), /invalid JSON/);
  assert.throws(
    () => parseExaResponse(JSON.stringify({ result: { content: [] } }), "application/json"),
    /no MCP messages/,
  );
});
