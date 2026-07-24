import assert from "node:assert/strict";
import { inspect } from "node:util";
import test from "node:test";

import {
  redact,
  redactUrlForDisplay,
  redactUrlsInText,
  reveal,
} from "../redaction.ts";

test("redacted values cannot leak through normal string, JSON, or inspect projections", () => {
  const secret = redact("moon-token");
  assert.equal(String(secret), "<redacted>");
  assert.equal(JSON.stringify(secret), "\"<redacted>\"");
  assert.equal(inspect(secret), "<redacted>");
  assert.equal(reveal(secret), "moon-token");
});

test("URL display redaction masks user info and common secret query keys", () => {
  const safe = redactUrlForDisplay(
    "https://user:password@example.com/docs?token=abc&view=full&signature=xyz",
  );
  assert.equal(safe, "https://<redacted>@example.com/docs?token=<redacted>&view=full&signature=<redacted>");
  assert.doesNotMatch(safe, /user|password|abc|xyz/);
});

test("URL redaction works inside result text without eating punctuation", () => {
  assert.equal(
    redactUrlsInText("See https://example.com/a?api_key=secret, then continue."),
    "See https://example.com/a?api_key=<redacted>, then continue.",
  );
});
