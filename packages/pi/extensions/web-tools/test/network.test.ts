import assert from "node:assert/strict";
import test from "node:test";

import { isBlockedIp, parsePublicUrl } from "../network.ts";

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
