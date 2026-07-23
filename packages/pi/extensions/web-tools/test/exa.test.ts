import assert from "node:assert/strict";
import test from "node:test";

import { formatSearchResults, parseSearchResults } from "../exa.ts";

const fixture = `Title: Official documentation
URL: https://example.com/docs
Published Date: 2026-01-02
Author: Example
Text: Primary result text.

Title: Unsafe result
URL: javascript:alert(1)
Text: This must not survive.

Title: Second result
URL: https://example.org/
Text: Secondary result text.`;

test("parseSearchResults normalizes usable HTTP results", () => {
  const results = parseSearchResults(fixture);
  assert.equal(results.length, 2);
  assert.deepEqual(results[0], {
    title: "Official documentation",
    url: "https://example.com/docs",
    published: "2026-01-02",
    source: "Example",
    snippet: "Primary result text.",
  });
  assert.equal(results[1]?.url, "https://example.org/");
});

test("formatSearchResults produces concise numbered output", () => {
  const output = formatSearchResults("example query", parseSearchResults(fixture));
  assert.match(output, /^Search results for: example query/);
  assert.match(output, /1\. Official documentation/);
  assert.match(output, /2\. Second result/);
  assert.doesNotMatch(output, /Unsafe result/);
});
