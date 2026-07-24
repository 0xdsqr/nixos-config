import assert from "node:assert/strict";
import test from "node:test";

import {
  cloakText,
  globToRegExp,
  loadCloakState,
  parseCloakConfig,
  toolResultPaths,
} from "../cloak.ts";

test("default file globs match envrc, local Nix, and private-key files", () => {
  assert.equal(globToRegExp("**/.env.*").test("/repo/.env.local"), true);
  assert.equal(globToRegExp("**/*.local.nix").test("/repo/hosts/dev.local.nix"), true);
  assert.equal(globToRegExp("**/*.pem").test("/repo/cert.pem"), true);
  assert.equal(globToRegExp("**/*.pem").test("/repo/cert.pem.txt"), false);
});

test("environment and local Nix files redact assignment values", () => {
  const state = parseCloakConfig({});
  const env = cloakText(
    "export API_URL=https://example.com\nTOKEN=super-secret\n# comment\nuse flake",
    ["/repo/.envrc.local"],
    "/repo",
    state,
  );
  assert.equal(
    env.text,
    "export API_URL=[REDACTED]\nTOKEN=[REDACTED]\n# comment\nuse flake",
  );

  const nix = cloakText(
    'servicePort = 8080;\napiToken = "hidden";',
    ["/repo/hosts/dev.local.nix"],
    "/repo",
    state,
  );
  assert.equal(nix.text, "servicePort = [REDACTED]\napiToken = [REDACTED]");
});

test("private material is fully replaced with a fixed marker", () => {
  const state = parseCloakConfig({});
  const result = cloakText("-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----", ["id.key"], "/repo", state);
  assert.equal(result.text, "[REDACTED] sensitive file contents");
  assert.equal(result.replacements, 1);
});

test("generic detection covers command and search output", () => {
  const state = parseCloakConfig({});
  const input = [
    'client_secret: "very private value"',
    "Authorization: Bearer abcdefghijklmnop",
    "https://alice:hunter2@example.com/path?token=query-secret",
    "github_pat_abcdefghijklmnopqrstuvwxyz123456",
  ].join("\n");
  const result = cloakText(input, [], "/repo", state);
  assert.doesNotMatch(result.text, /very private|abcdefghijklmnop|hunter2|query-secret|github_pat_/);
  assert.ok(result.replacements >= 5);
});

test("invalid custom configuration retains safe built-in defaults", () => {
  const state = parseCloakConfig({
    mask: "",
    rules: [{ files: [], mode: "invalid" }],
    patterns: [{ pattern: "(", flags: "z" }],
  });
  assert.ok(state.errors.length >= 3);
  assert.ok(state.rules.length >= 2);
  assert.equal(cloakText("TOKEN=secret", [".env"], "/repo", state).text, "TOKEN=[REDACTED]");
});

test("malformed config files fail closed to default detection", (t) => {
  const configPath = `${t.mock ? "/definitely/missing" : "/missing"}/cloak.json`;
  const state = loadCloakState(configPath);
  assert.equal(state.errors.length, 0);
  assert.equal(cloakText("password=secret", [], "/repo", state).text, "password=[REDACTED]");
});

test("tool path extraction includes grep globs and common custom path fields", () => {
  assert.deepEqual(
    toolResultPaths(
      "grep",
      { path: "/repo", glob: ".env*", file_path: "extra.env" },
      "/cwd",
      ".env.local:2: ORDINARY_NAME=secret",
    ),
    ["/repo", "extra.env", "/repo/.env*", "/repo/.env.local"],
  );
  assert.ok(toolResultPaths("bash", { command: "sed -n '1,20p' .envrc" }, "/repo").includes(".envrc"));
});

test("grep and bash path inference applies broad env-file assignment masking", () => {
  const state = parseCloakConfig({});
  const grepPaths = toolResultPaths(
    "grep",
    { path: "/repo" },
    "/repo",
    ".env.local:2: ORDINARY_NAME=secret",
  );
  assert.equal(
    cloakText(".env.local:2: ORDINARY_NAME=secret", grepPaths, "/repo", state).text,
    ".env.local:2: ORDINARY_NAME=[REDACTED]",
  );

  const bashPaths = toolResultPaths("bash", { command: "cat .envrc" }, "/repo");
  assert.equal(cloakText("ORDINARY_NAME=secret", bashPaths, "/repo", state).text, "ORDINARY_NAME=[REDACTED]");
});
