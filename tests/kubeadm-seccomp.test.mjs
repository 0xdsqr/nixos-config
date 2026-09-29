import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const source = read("modules/nixos/kubeadm.nix");

test("seccomp default is an optional per-node boolean with an explicit rollback", () => {
  assert.match(source, /kubelet.seccompDefault = mkOption \{\s*type = nullOr bool;\s*default = null;/);
  assert.match(source, /lib.optionalString \(cfg.kubelet.seccompDefault != null\)\s*" --seccomp-default=\$\{lib.boolToString cfg.kubelet.seccompDefault\}"/);
});

test("seccomp defaulting is scoped to all nine declared Indigo nodes and no other hosts", () => {
  const enabled = readdirSync(new URL("../hosts/", import.meta.url)).filter((name) => {
    try { return /kubelet.seccompDefault = true;/.test(read(`hosts/${name}/default.nix`)); }
    catch (error) { if (error.code === "ENOENT") return false; throw error; }
  }).sort();
  assert.deepEqual(enabled, [
    "srv-lx-k8s-indigo-control-01",
    "srv-lx-k8s-indigo-control-02",
    "srv-lx-k8s-indigo-control-03",
    "srv-lx-k8s-indigo-worker-01",
    "srv-lx-k8s-indigo-worker-02",
    "srv-lx-k8s-indigo-worker-03",
    "srv-lx-k8s-indigo-worker-04",
    "srv-lx-k8s-indigo-worker-05",
    "srv-lx-k8s-indigo-worker-06",
  ]);
});

test("node-local environment keeps the IP and triggers kubelet restart when changed", () => {
  assert.match(source, /"default\/kubelet" = mkIf \(cfg.nodeAddress != null\)/);
  assert.match(source, /text = "KUBELET_EXTRA_ARGS=--node-ip=\$\{cfg.nodeAddress\}"/);
  assert.match(source, /restartTriggers = optionals \(cfg.kubelet.seccompDefault != null && cfg.nodeAddress != null\) \[\s*config.environment.etc."default\/kubelet".source/);
  assert.match(source, /assertion = cfg.kubelet.seccompDefault == null \|\| cfg.nodeAddress != null/);
  assert.match(source, /EnvironmentFile = \[\s*"-\/var\/lib\/kubelet\/kubeadm-flags.env"\s*"-\/etc\/default\/kubelet"/);
  assert.match(source, /ExecStart = .*\$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS/);
});

test("node-local rollout does not change cluster-wide kubelet config or rewrite workload profiles", () => {
  const clusterConfig = source.split('kubeletConfig = renderYaml "kubelet.yaml"')[1].split("reconcileKubeletServerTlsBootstrap =")[0];
  assert.doesNotMatch(clusterConfig, /seccompDefault/);
  const executable = source.replace(/^\s*#.*$/gm, "");
  assert.doesNotMatch(executable, /kubectl (patch|delete|drain)|seccompProfile\s*=/);
});
