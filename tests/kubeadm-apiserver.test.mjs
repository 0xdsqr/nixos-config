import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const source = read("modules/nixos/kubeadm.nix");
const policy = read("modules/nixos/kubeadm/audit-policy.yaml");
const apiServer = source.split("kubeadmClusterConfig =")[1].split('apiVersion = "kubeadm.k8s.io/v1beta4";')[0];
const args = Object.fromEntries([...apiServer.matchAll(/name = "([a-z-]+)";\s*value = "([^"]+)";/g)].map((m) => [m[1], m[2]]));

test("API hardening is opt-in and enabled only on the three Indigo control planes", () => {
  assert.match(source, /apiServerHardening.enable = mkEnableOption/);
  assert.match(apiServer, /lib.optionalAttrs cfg.apiServerHardening.enable/);
  assert.match(source, /!cfg.apiServerHardening.enable\s*\|\| \(\s*cfg.role == "control-plane"\s*&& cfg.kubelet.serverTlsBootstrap/);
  const optedIn = readdirSync(new URL("../hosts/", import.meta.url)).filter((name) => {
    try { return /apiServerHardening.enable = true;/.test(read(`hosts/${name}/default.nix`)); }
    catch (error) { if (error.code === "ENOENT") return false; throw error; }
  }).sort();
  assert.deepEqual(optedIn, ["srv-lx-k8s-indigo-control-01", "srv-lx-k8s-indigo-control-02", "srv-lx-k8s-indigo-control-03"]);
});

test("API arguments verify kubelet identity and bound local audit storage", () => {
  assert.deepEqual(args, {
    "kubelet-certificate-authority": "/etc/kubernetes/pki/ca.crt",
    "audit-policy-file": "/etc/kubernetes/audit/policy.yaml",
    "audit-log-path": "/var/log/kubernetes/audit/audit.log",
    "audit-log-mode": "blocking",
    "audit-log-maxage": "14",
    "audit-log-maxbackup": "10",
    "audit-log-maxsize": "100",
  });
  assert.match(apiServer, /certSANs = \[ cfg.cluster.apiVip \]/);
  assert.doesNotMatch(apiServer, /anonymous-auth|authorization-mode|encryption-provider|insecure/);
});

test("audit mounts are least-privilege and logs live outside the Nix store", () => {
  assert.match(apiServer, /name = "audit-policy";\s*hostPath = "\/etc\/kubernetes\/audit\/policy.yaml";\s*mountPath = "\/etc\/kubernetes\/audit\/policy.yaml";\s*readOnly = true;\s*pathType = "File";/);
  assert.match(apiServer, /name = "audit-logs";\s*hostPath = "\/var\/log\/kubernetes\/audit";\s*mountPath = "\/var\/log\/kubernetes\/audit";\s*readOnly = false;\s*pathType = "Directory";/);
  assert.match(source, /optionals cfg.apiServerHardening.enable \[[\s\S]*?"d \/var\/log\/kubernetes\/audit 0700 root root -"/);
});

test("audit policy logs metadata only, including Secret and authentication requests", () => {
  const config = policy.replace(/^\s*#.*$/gm, "");
  assert.match(config, /^apiVersion: audit.k8s.io\/v1\nkind: Policy/m);
  assert.match(config, /omitStages:\s+- RequestReceived\nomitManagedFields: true/);
  assert.deepEqual([...config.matchAll(/- level: (\w+)/g)].map((m) => m[1]), ["None", "Metadata"]);
  assert.match(config, /- level: None\s+verbs: \[get\]\s+nonResourceURLs: \[\/healthz, \/healthz\/\*, \/livez, \/livez\/\*, \/readyz, \/readyz\/\*\]\s+- level: Metadata\s*$/);
  assert.doesNotMatch(config, /users:|userGroups:|resources:|RequestResponse|level: Request\b/);
});

test("init and per-node reconfiguration share ClusterConfiguration without automatic activation", () => {
  assert.match(source, /"kubernetes\/kubeadm\/control-plane.yaml" = mkIf cfg.apiServerHardening.enable \{\s*source = pkgs.concatText "kubeadm-control-plane.yaml" \[\s*kubeadmConfig\s*kubeadmClusterConfig\s*\]/);
  assert.match(source, /"kubernetes\/kubeadm\/init.yaml" = mkIf cfg.bootstrap \{\s*source = pkgs.concatText "kubeadm-init.yaml" \[\s*kubeadmConfig\s*kubeadmClusterConfig\s*kubeletConfig/);
  assert.match(source, /advertiseAddress = cfg.nodeAddress/);
  assert.match(source, /"kubernetes\/audit\/policy.yaml" = mkIf cfg.apiServerHardening.enable \{\s*source = .\/kubeadm\/audit-policy.yaml/);
  // Operational examples are comments, never activation/systemd hooks.
  const executableSource = source.replace(/^\s*#.*$/gm, "");
  assert.doesNotMatch(executableSource, /kubeadm init phase|manifests\/kube-apiserver.yaml|systemd.services.*apiserver/);
});
