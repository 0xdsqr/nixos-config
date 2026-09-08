import assert from "node:assert/strict";
import { readdirSync } from "node:fs";
import test from "node:test";
import { inventory, moduleSource, read, renderRules } from "./helpers/kubeadm-firewall.mjs";

test("internal-port restrictions are default-off with only the six Indigo nodes opted in", () => {
  assert.match(moduleSource, /nodeFirewall = \{\s*enable = mkEnableOption/);
  assert.match(moduleSource, /!cfg\.nodeFirewall\.enable\s*\|\|/);
  assert.match(moduleSource, /builtins\.elem cfg\.nodeAddress cfg\.nodeFirewall\.nodeAddresses/);
  const hosts = readdirSync(new URL("../hosts/", import.meta.url), { withFileTypes: true }).filter((e) => e.isDirectory());
  const optedIn = hosts.filter(({ name }) => {
    try { return /nodeFirewall\.enable = true;/.test(read(`hosts/${name}/default.nix`)); }
    catch (error) { if (error.code === "ENOENT") return false; throw error; }
  }).map(({ name }) => name).sort();
  assert.deepEqual(optedIn, [
    "srv-lx-k8s-indigo-control-01",
    "srv-lx-k8s-indigo-control-02",
    "srv-lx-k8s-indigo-control-03",
    "srv-lx-k8s-indigo-worker-01",
    "srv-lx-k8s-indigo-worker-02",
    "srv-lx-k8s-indigo-worker-03",
  ]);
  for (const host of optedIn) {
    assert.match(read(`hosts/${host}/default.nix`), /profiles\/kubernetes\/indigo-firewall\.nix/);
  }
  assert.doesNotMatch(read("profiles/kubernetes/nixos.nix"), /nodeFirewall|indigo-firewall/);
});

test("shared Indigo peer inventory matches its six declared nodes and roles", () => {
  const nodes = [], controls = [], workers = [];
  for (const role of ["control", "worker"]) for (const suffix of ["01", "02", "03"]) {
    const source = read(`hosts/srv-lx-k8s-indigo-${role}-${suffix}/default.nix`);
    const address = source.match(/nodeAddress = "([0-9.]+)";/)[1];
    nodes.push(address);
    (role === "control" ? controls : workers).push(address);
  }
  assert.deepEqual(inventory.nodeAddresses, nodes);
  assert.deepEqual(inventory.controlPlaneAddresses, controls);
  assert.deepEqual(inventory.memberlistAddresses, workers);
  assert.deepEqual(inventory.podSubnets, ["10.80.0.0/16"]);
});

test("worker rules limit kubelet, health, VXLAN and memberlist without etcd exposure", () => {
  const rules = renderRules("worker", "10.10.80.105");
  const lines = rules.split("\n");
  assert.equal(lines.length, 4);
  assert.match(lines[0], /10\.80\.0\.0\/16 \} tcp dport \{ 4240, 10250 \}/);
  assert.match(lines[1], /udp dport 8472/);
  assert.doesNotMatch(lines[1], /10\.80\.0\.0\/16/);
  for (const line of lines.slice(2)) {
    assert.match(line, /^ip saddr \{ 10\.10\.80\.103, 10\.10\.80\.104, 10\.10\.80\.105 \}/);
    assert.match(line, /dport 7946/);
  }
  assert.doesNotMatch(rules, /2379|2380|10257|10259|0\.0\.0\.0\/0/);
});

test("control-plane rules allow only stacked-etcd peers and no MetalLB memberlist", () => {
  const rules = renderRules("control-plane", "10.10.80.100");
  assert.equal(rules.split("\n").length, 3);
  assert.match(rules, /ip saddr \{ 10\.10\.80\.100, 10\.10\.80\.101, 10\.10\.80\.102 \} tcp dport \{ 2379, 2380 \}/);
  assert.doesNotMatch(rules, /7946|10257|10259/);
});

test("legacy behavior, API access and existing proxy rules are preserved outside opt-in", () => {
  assert.match(moduleSource, /optionals \(!cfg\.nodeFirewall\.enable\) \[\s*10250\s*4240\s*7946\s*\]/);
  assert.match(moduleSource, /allowedUDPPorts = optionals \(!cfg\.nodeFirewall\.enable\) \[\s*7946\s*8472\s*\]/);
  assert.match(moduleSource, /cfg\.role == "control-plane" && cfg\.nodeFirewall\.enable\) \[ cfg\.cluster\.apiPort \]/);
  assert.match(moduleSource, /cfg\.role == "control-plane" && !cfg\.nodeFirewall\.enable\) \[\s*2379\s*2380\s*6443\s*10257\s*10259\s*\]/);
  assert.match(moduleSource, /extraInputRules = mkMerge/);
  assert.match(moduleSource, /mkIf cfg\.nodeFirewall\.enable nodeFirewallRules/);
  assert.doesNotMatch(moduleSource, /trustedInterfaces\s*=|tailscale\.[A-Za-z]+\s*=/);
});
