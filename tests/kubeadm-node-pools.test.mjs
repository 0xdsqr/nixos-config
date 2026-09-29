import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
const read = path => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");

test("CoreDNS pool placement stays kubeadm-owned and explicitly opted in", () => {
  const source = read("modules/nixos/kubeadm.nix");
  assert.match(source, /coreDnsHardening.platformPool = mkEnableOption/);
  assert.ok(source.includes('cfg.coreDnsHardening.enable && cfg.coreDnsHardening.platformPool && cfg.role == "control-plane"'));
  assert.ok(source.includes('source = ./kubeadm/corednsdeployment-platform+strategic.yaml;'));
  for (const suffix of ["01", "02", "03"]) {
    assert.ok(read(`hosts/srv-lx-k8s-indigo-control-${suffix}/default.nix`).includes("coreDnsHardening.platformPool = true;"));
  }
});

test("placement patch preserves kubeadm exceptions and leaves DNS/security/availability untouched", () => {
  const patch = read("modules/nixos/kubeadm/corednsdeployment-platform+strategic.yaml");
  for (const field of ["platform.dsqr.dev/node-pool: platform", "platform.dsqr.dev/dedicated", "effect: NoSchedule", "CriticalAddonsOnly", "node-role.kubernetes.io/control-plane"]) assert.ok(patch.includes(field));
  assert.doesNotMatch(patch, /replicas:|containers:|image:|securityContext:|topologySpreadConstraints:|NoExecute/);
});
