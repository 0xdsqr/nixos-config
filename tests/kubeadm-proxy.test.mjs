import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import test from "node:test";

const root = new URL("../", import.meta.url);
const read = (path) => readFileSync(new URL(path, root), "utf8");
const module = read("modules/nixos/kubeadm.nix");

// Fast source-contract tests, not a substitute for Nix evaluation or live
// endpoint-recreation / TCP+UDP DNS tests after the first node is rebuilt.
test("proxy routing compatibility is default-off and only the six Indigo nodes opt in", () => {
  assert.match(module, /routingCompatibility\.enable = mkEnableOption/);
  assert.match(module, /!cfg\.ciliumProxyFirewall\.routingCompatibility\.enable\s*\|\|/);
  assert.doesNotMatch(read("profiles/kubernetes/nixos.nix"), /routingCompatibility/);
  const optedIn = readdirSync(new URL("hosts/", root), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .filter((entry) => {
      try {
        return /ciliumProxyFirewall\.routingCompatibility\.enable = true;/.test(
          read(`hosts/${entry.name}/default.nix`),
        );
      } catch (error) {
        if (error.code === "ENOENT") return false;
        throw error;
      }
    })
    .map((entry) => entry.name)
    .sort();
  assert.deepEqual(optedIn, [
    "srv-lx-k8s-indigo-control-01",
    "srv-lx-k8s-indigo-control-02",
    "srv-lx-k8s-indigo-control-03",
    "srv-lx-k8s-indigo-worker-01",
    "srv-lx-k8s-indigo-worker-02",
    "srv-lx-k8s-indigo-worker-03",
  ]);
});

test("accept_local is opt-in and limited to dynamically named Cilium endpoint interfaces", () => {
  assert.match(
    module,
    /"net\.ipv4\.conf\.lxc\*\.accept_local" = mkIf cfg\.ciliumProxyFirewall\.routingCompatibility\.enable 1;/,
  );
  assert.doesNotMatch(module, /"net\.ipv4\.conf\.(?:all|default|ens18|ts0)\.(?:accept_local|src_valid_mark|rp_filter)"\s*=/);
  assert.doesNotMatch(module, /lxc[a-f0-9]{12}|10\.80\.5\.63/);
});

test("both firewall hooks use interface-scoped Cilium marks, without opening proxy ports", () => {
  const rules = module.match(/ciliumProxyRoutingRules = ''\n([\s\S]*?)\n\s*'';/)?.[1];
  assert.ok(rules);
  const lines = rules.trim().split("\n").map((line) => line.trim());
  assert.equal(lines.length, 2);
  assert.match(lines[0], /^iifname "lxc\*" /);
  assert.match(lines[1], /^iifname \{ "cilium_host", "cilium_net", "cilium_vxlan" \} /);
  for (const line of lines) {
    assert.match(line, /meta mark & 0x00000f00 == 0x00000200 counter accept/);
    assert.doesNotMatch(line, /ts0|ens18|dport|sport/);
  }
  assert.match(module, /if cfg\.ciliumProxyFirewall\.routingCompatibility\.enable then\s*ciliumProxyRoutingRules\s*else/);
  assert.match(module, /extraReversePathFilterRules = mkIf cfg\.ciliumProxyFirewall\.routingCompatibility\.enable ciliumProxyRoutingRules;/);
  // The pre-existing input exception remains unchanged for other nodes.
  assert.match(module, /else\s*''\s*meta mark & 0x00000f00 == 0x00000200 counter accept comment "Cilium policy proxy traffic"/);
});
