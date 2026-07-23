import assert from "node:assert/strict";
import test from "node:test";

import { truncateOutput } from "../output.ts";

test("truncateOutput preserves normal output", () => {
  assert.deepEqual(truncateOutput("small\noutput"), {
    text: "small\noutput",
    truncated: false,
  });
});

test("truncateOutput limits lines", () => {
  const result = truncateOutput(Array.from({ length: 2_010 }, (_, index) => `line ${index}`).join("\n"));
  assert.equal(result.truncated, true);
  assert.equal(result.text.split("\n").length, 2_000);
});

test("truncateOutput limits UTF-8 bytes without splitting characters", () => {
  const result = truncateOutput("🌙".repeat(20_000));
  assert.equal(result.truncated, true);
  assert.ok(Buffer.byteLength(result.text) <= 50 * 1024);
  assert.doesNotMatch(result.text, /\uFFFD/);
});
