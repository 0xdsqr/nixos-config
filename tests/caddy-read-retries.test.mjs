import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const source = read("modules/nixos/caddy.nix");
const host = read("hosts/srv-lx-gateway/default.nix");

test("bounded read retries are opt-in and enabled only on Indigo's private Argo route", () => {
  assert.ok(source.includes("retryReadRequests = mkEnableOption"));
  assert.equal((host.match(/retryReadRequests = true;/g) ?? []).length, 1);
  const indigo = host.split('"argocd.indigo.home.arpa" = {')[1].split("};")[0];
  assert.ok(indigo.includes("retryReadRequests = true;"));
  assert.ok(indigo.includes('upstream = "https://10.10.80.200";'));
  assert.ok(indigo.includes('tlsServerName = "argocd.indigo.home.arpa";'));
  assert.ok(!indigo.includes("tlsInsecureSkipVerify"));
});

test("safe reads get a separate bounded handler, not just a retry matcher", () => {
  assert.ok(source.includes('optionalString route.retryReadRequests "@retryableReads method GET HEAD"'));
  assert.ok(source.includes('reverse_proxy ${optionalString retryReads "@retryableReads "}${upstreams}'));
  assert.ok(source.includes("${optionalString route.retryReadRequests (mkReverseProxy route true)}\n              ${mkReverseProxy route false}"));
  const retry = source.split("${optionalString retryReads ''")[1].split("''}")[0];
  assert.deepEqual(retry.trim().split("\n").map(line => line.trim()), [
    "lb_retries 2", "lb_try_duration 2s", "lb_try_interval 250ms", "lb_retry_match method GET HEAD",
  ]);
  assert.ok(source.includes('optionalString (!retryReads) "lb_try_duration ${route.failover.tryDuration}"'));
});

test("both proxy handlers preserve upstream identity, TLS verification and the source allowlist", () => {
  assert.ok(source.includes('optionalString hasHostHeader "header_up Host ${route.hostHeader}"'));
  assert.ok(source.includes('"tls_server_name ${route.tlsServerName}"'));
  assert.ok(source.includes('optionalString route.tlsInsecureSkipVerify "tls_insecure_skip_verify"'));
  assert.ok(/tlsInsecureSkipVerify = mkOption \{\s*type = bool;\s*default = false;/.test(source));
  assert.ok(source.includes("@internal remote_ip ${internalSourceRanges}"));
  assert.ok(source.includes("handle @internal {"));
  assert.ok(source.includes("respond 403"));
});

// Parse a representative Caddyfile using the installed gateway binary, without
// loading/reloading a service. This supplements source tests, not a Nix build.
test("installed Caddy routes GET/HEAD to retries and all other methods to the unchanged proxy", {
  skip: !process.env.CADDY_TEST_SSH_HOST,
}, () => {
  const target = process.env.CADDY_TEST_SSH_HOST;
  assert.match(target, /^[a-zA-Z0-9.-]+$/);
  const retry = source.split("${optionalString retryReads ''")[1].split("''}")[0].trim();
  const input = `http://argocd.indigo.home.arpa {
    @internal remote_ip 10.0.0.0/8
    @retryableReads method GET HEAD
    handle @internal {
      reverse_proxy @retryableReads https://10.10.80.200 {
        header_up Host argocd.indigo.home.arpa
        ${retry}
        transport http {
          tls_server_name argocd.indigo.home.arpa
        }
      }
      reverse_proxy https://10.10.80.200 {
        header_up Host argocd.indigo.home.arpa
        transport http {
          tls_server_name argocd.indigo.home.arpa
        }
      }
    }
    respond 403
  }`;
  let result;
  try {
    const unit = execFileSync("ssh", ["-o", "BatchMode=yes", "-o", "ConnectTimeout=8", target,
      "systemctl show caddy -p ExecStart --value"], {
      encoding: "utf8", timeout: 15000, stdio: ["ignore", "pipe", "pipe"],
    });
    const binary = unit.match(/path=(\/nix\/store\/[a-z0-9-]+(?:\.[a-z0-9-]+)*\/bin\/caddy) ;/)?.[1];
    assert.ok(binary, "Caddy executable must be resolved from its running systemd unit");
    result = execFileSync("ssh", ["-o", "BatchMode=yes", "-o", "ConnectTimeout=8", target,
      `${binary} adapt --adapter caddyfile --config /dev/stdin`], {
      input, encoding: "utf8", timeout: 20000, maxBuffer: 1024 * 1024, stdio: ["pipe", "pipe", "pipe"],
    });
  } catch { assert.fail("Read-only remote Caddy adaptation failed"); }
  const config = JSON.parse(result);
  const found = [];
  function visit(value) {
    if (!value || typeof value !== "object") return;
    if (Array.isArray(value.handle)) {
      for (const handler of value.handle) {
        if (handler.handler === "reverse_proxy") found.push({ route: value, handler });
      }
    }
    for (const child of Object.values(value)) visit(child);
  }
  visit(config);
  assert.equal(found.length, 2);
  assert.deepEqual(found[0].route.match, [{ method: ["GET", "HEAD"] }]);
  assert.equal(found[1].route.match, undefined);
  assert.deepEqual(found[0].handler.load_balancing, {
    retries: 2, try_duration: 2000000000, try_interval: 250000000, retry_match: [{ method: ["GET", "HEAD"] }],
  });
  assert.equal(found[1].handler.load_balancing, undefined);
  for (const { handler } of found) {
    assert.deepEqual(handler.upstreams, [{ dial: "10.10.80.200:443" }]);
    assert.equal(handler.transport.tls.server_name, "argocd.indigo.home.arpa");
    assert.equal(handler.transport.tls.insecure_skip_verify, undefined);
  }
});
