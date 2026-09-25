import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const source = read("modules/nixos/kubeadm.nix");

test("CoreDNS hardening is opt-in only on Indigo control planes", () => {
  assert.match(source, /coreDnsHardening.enable = mkEnableOption/);
  const optedIn = readdirSync(new URL("../hosts/", import.meta.url)).filter(name => {
    try { return /coreDnsHardening.enable = true;/.test(read(`hosts/${name}/default.nix`)); }
    catch (error) { if (error.code === "ENOENT") return false; throw error; }
  }).sort();
  assert.deepEqual(optedIn, ["srv-lx-k8s-indigo-control-01", "srv-lx-k8s-indigo-control-02", "srv-lx-k8s-indigo-control-03"]);
});

test("kubeadm owns the patch and explicit upgrade configurations retain it", () => {
  assert.match(source, /lib.optionalAttrs cfg.coreDnsHardening.enable/);
  assert.match(source, /patches.directory = "\/etc\/kubernetes\/kubeadm\/patches"/);
  assert.match(source, /cfg.coreDnsHardening.enable && cfg.role == "control-plane"/);
  assert.match(source, /source = .\/kubeadm\/corednsdeployment-security\+strategic.yaml/);
  assert.match(source, /kind = "UpgradeConfiguration"/);
  for (const phase of ["apply", "node"]) {
    assert.ok(source.includes(`${phase}.patches.directory = "/etc/kubernetes/kubeadm/patches";`));
  }
});

test("CoreDNS patch preserves its identity and DNS binding without replacing the deployment", () => {
  const patch = read("modules/nixos/kubeadm/corednsdeployment-security+strategic.yaml");
  for (const field of ["runAsNonRoot: true", "runAsUser: 65532", "runAsGroup: 65532", "type: RuntimeDefault", "allowPrivilegeEscalation: false", "readOnlyRootFilesystem: true", "drop: [ALL]", "add: [NET_BIND_SERVICE]"]) {
    assert.ok(patch.includes(field), field);
  }
  assert.doesNotMatch(patch, /image:|replicas:|hostNetwork:|automountServiceAccountToken:|args:|command:/);
});

test("CoreDNS availability preserves replicas and networking while preventing voluntary rollout loss", () => {
  const patch = read("modules/nixos/kubeadm/corednsdeployment-security+strategic.yaml");
  for (const field of ["type: RollingUpdate", "maxSurge: 1", "maxUnavailable: 0", "maxSkew: 1", "minDomains: 2", "topologyKey: kubernetes.io/hostname", "whenUnsatisfiable: DoNotSchedule", "nodeTaintsPolicy: Honor", "k8s-app: kube-dns"]) {
    assert.ok(patch.includes(field), field);
  }
  assert.doesNotMatch(patch, /replicas:|tolerations:|nodeSelector:|affinity:|hostNetwork:|dnsPolicy:|image:/);
});
