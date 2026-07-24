import assert from "node:assert/strict";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import test from "node:test";

import {
  acceptHeader,
  composeSignal,
  fetchPinned,
  isBlockedIp,
  parsePublicUrl,
  readLimitedBody,
  readLimitedIncomingBody,
} from "../network.ts";

test("parsePublicUrl accepts public HTTP URLs and removes fragments", () => {
  assert.equal(parsePublicUrl("https://example.com/docs?q=1#private").href, "https://example.com/docs?q=1");
  assert.equal(parsePublicUrl("../next", "https://example.com/docs/start").href, "https://example.com/next");
});

test("parsePublicUrl rejects unsafe schemes and credentials", () => {
  assert.throws(() => parsePublicUrl("file:///etc/passwd"), /http/);
  assert.throws(() => parsePublicUrl("https://user:secret@example.com"), /credentials/);
  assert.throws(() => parsePublicUrl("not a url"), /Invalid URL/);
});

test("isBlockedIp blocks private, local, reserved, and documentation ranges", () => {
  for (const address of [
    "0.0.0.0",
    "10.1.2.3",
    "127.0.0.1",
    "169.254.169.254",
    "172.16.0.1",
    "192.168.1.1",
    "198.51.100.1",
    "203.0.113.1",
    "::1",
    "fd00::1",
    "fe80::1",
    "2001:db8::1",
    "::ffff:127.0.0.1",
    "::ffff:7f00:1",
  ]) {
    assert.equal(isBlockedIp(address), true, address);
  }
});

test("isBlockedIp permits representative public addresses", () => {
  assert.equal(isBlockedIp("8.8.8.8"), false);
  assert.equal(isBlockedIp("2606:4700:4700::1111"), false);
});

test("Accept headers prefer the requested representation", () => {
  assert.match(acceptHeader("markdown"), /^text\/markdown/);
  assert.match(acceptHeader("text"), /^text\/plain/);
  assert.match(acceptHeader("html"), /^text\/html/);
});

test("operation signals propagate cancellation and clean up", () => {
  const parent = new AbortController();
  const operation = composeSignal(parent.signal, 30);
  parent.abort(new Error("stop"));
  assert.equal(operation.signal.aborted, true);
  operation.cleanup();
});

test("bounded response reads reject declared and streamed overflow", async () => {
  await assert.rejects(
    () => readLimitedBody(new Response("tiny", { headers: { "content-length": "9" } }), 8),
    /limit/,
  );
  await assert.rejects(
    () => readLimitedBody(new Response("ninebytes"), 8),
    /limit/,
  );
});

test("operation signals enforce timeout", async () => {
  const operation = composeSignal(undefined, 0.005);
  await new Promise((resolve) => setTimeout(resolve, 15));
  assert.equal(operation.signal.aborted, true);
  operation.cleanup();
});

test("pinned transport connects to the validated address while preserving the URL host", async (t) => {
  let observedHost = "";
  let observedPath = "";
  let observedUserAgent = "";
  const server = createServer((request, response) => {
    observedHost = request.headers.host ?? "";
    observedPath = request.url ?? "";
    observedUserAgent = request.headers["user-agent"] ?? "";
    response.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    response.end("pinned response");
  });
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  t.after(() => new Promise<void>((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  }));

  const port = (server.address() as AddressInfo).port;
  const response = await fetchPinned(
    new URL(`http://public.example:${port}/docs/page?q=one`),
    { address: "127.0.0.1", family: 4 },
    AbortSignal.timeout(1_000),
    "text/plain",
    "pi-web-tools-test",
  );
  const body = await readLimitedIncomingBody(response, 1_024);

  assert.equal(new TextDecoder().decode(body), "pinned response");
  assert.equal(observedHost, `public.example:${port}`);
  assert.equal(observedPath, "/docs/page?q=one");
  assert.equal(observedUserAgent, "pi-web-tools-test");
});
