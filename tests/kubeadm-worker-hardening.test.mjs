import assert from "node:assert/strict";
import { chmodSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const root = fileURLToPath(new URL("../", import.meta.url));
const read = (path) => readFileSync(join(root, path), "utf8");
const source = read("modules/nixos/kubeadm.nix");
const profile = read("profiles/kubernetes/indigo-worker-hardening.nix");

test("TLS reconciliation declares cmp's package instead of relying on the host PATH", () => {
  const reconcile = source.split("reconcileKubeletServerTlsBootstrap = pkgs.writeShellApplication {")[1].split("workerRuntimeOverlay =")[0];
  assert.match(reconcile, /pkgs.diffutils/);
  assert.match(reconcile, /cmp --silent/);
});

test("only the six Indigo workers import the resource profile", () => {
  const selected = readdirSync(join(root, "hosts")).filter((name) => {
    try { return read(`hosts/${name}/default.nix`).includes("../../profiles/kubernetes/indigo-worker-hardening.nix"); }
    catch (error) { if (error.code === "ENOENT") return false; throw error; }
  }).sort();
  assert.deepEqual(selected, Array.from({ length: 6 }, (_, i) => `srv-lx-k8s-indigo-worker-0${i + 1}`));
  assert.match(source, /!cfg.kubelet.workerHardening.enable \|\| cfg.role == "worker"/);
});

test("budgets are overrideable defaults and do not enforce hard system-service caps", () => {
  assert.equal((profile.match(/cpu = lib.mkDefault "250m"/g) ?? []).length, 2);
  assert.equal((profile.match(/memory = lib.mkDefault "512Mi"/g) ?? []).length, 2);
  assert.equal((profile.match(/ephemeral-storage = lib.mkDefault "1Gi"/g) ?? []).length, 2);
  assert.equal((profile.match(/pid = lib.mkDefault "1000"/g) ?? []).length, 2);
  assert.match(profile, /podPidsLimit = lib.mkDefault 4096/);
  assert.match(source, /enforceNodeAllocatable = \[ "pods" \]/);
  assert.doesNotMatch(profile, /MemoryMax|CPUQuota|firewall|tailscale/);
});

test("shutdown budget preserves 360 seconds for regular Pods and 60 for critical Pods", () => {
  assert.match(profile, /shutdownGraceSeconds = lib.mkDefault 420/);
  assert.match(profile, /criticalShutdownGraceSeconds = lib.mkDefault 60/);
  assert.match(source, /InhibitDelayMaxSec[\s\S]*?shutdownGraceSeconds \+ 30/);
  assert.match(source, /criticalShutdownGraceSeconds\s*< cfg.kubelet.workerHardening.shutdownGraceSeconds/);
});

test("runtime overlay is private, restarts on change, and disabling restores the original config path", () => {
  assert.match(source, /if cfg.kubelet.workerHardening.enable\s*then\s*"\/run\/kubelet\/worker-config.yaml"\s*else\s*"\/var\/lib\/kubelet\/config.yaml"/);
  assert.match(source, /optionals cfg.kubelet.workerHardening.enable \[ workerRuntimeOverlay \]/);
  assert.match(source, /RuntimeDirectoryMode = mkIf cfg.kubelet.workerHardening.enable "0700"/);
  assert.match(source, /--config=\$\{effectiveKubeletConfig\}/);
  const clusterConfig = source.split('kubeletConfig = renderYaml "kubelet.yaml"')[1].split("reconcileKubeletServerTlsBootstrap =")[0];
  assert.doesNotMatch(clusterConfig, /workerHardening|kubeReserved|podPidsLimit/);
});

const hasTools = spawnSync("yq", ["--version"], { encoding: "utf8" }).status === 0
  && spawnSync("chown", ["--version"], { encoding: "utf8" }).status === 0;

test("runtime generator preserves kubeadm fields, permissions and last-good output on invalid input", { skip: !hasTools && "run with yq-go and GNU coreutils on PATH" }, () => {
  const dir = mkdtempSync(join(tmpdir(), "kubelet-worker-test-"));
  const base = join(dir, "config.yaml");
  const overlay = join(dir, "overlay.json");
  const output = join(dir, "effective.yaml");
  const original = {
    apiVersion: "kubelet.config.k8s.io/v1beta1", kind: "KubeletConfiguration",
    authentication: { anonymous: { enabled: false }, webhook: { enabled: true }, x509: { clientCAFile: "/etc/kubernetes/pki/ca.crt" } },
    authorization: { mode: "Webhook" }, clusterDNS: ["10.81.0.10"], clusterDomain: "cluster.local",
    cgroupDriver: "systemd", rotateCertificates: true, serverTLSBootstrap: true, seccompDefault: false,
    resolvConf: "/etc/resolv.conf", staticPodPath: "/etc/kubernetes/manifests", featureGates: { ExamplePreserved: true },
    evictionHard: { "memory.available": "100Mi", "nodefs.available": "10%" },
  };
  const settings = {
    kubeReserved: { cpu: "250m", memory: "512Mi", "ephemeral-storage": "1Gi", pid: "1000" },
    systemReserved: { cpu: "250m", memory: "512Mi", "ephemeral-storage": "1Gi", pid: "1000" },
    podPidsLimit: 4096, enforceNodeAllocatable: ["pods"], shutdownGracePeriod: "420s", shutdownGracePeriodCriticalPods: "60s",
  };
  const run = (input = base, destination = output) => spawnSync("bash", [join(root, "modules/nixos/kubeadm/prepare-worker-config.sh"), input, overlay, destination], { encoding: "utf8" });
  const decoded = () => {
    // Parse the bytes kubelet receives, not a repaired yq re-serialization.
    return JSON.parse(readFileSync(output, "utf8"));
  };
  try {
    writeFileSync(base, JSON.stringify(original));
    chmodSync(base, 0o644);
    writeFileSync(overlay, JSON.stringify(settings));
    let result = run();
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(decoded(), { ...original, ...settings });
    assert.equal(readFileSync(base, "utf8"), JSON.stringify(original));
    assert.equal(statSync(base).mode & 0o777, 0o600);
    assert.equal(statSync(output).mode & 0o777, 0o600);
    const first = readFileSync(output, "utf8");
    result = run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(readFileSync(output, "utf8"), first);
    // kubeadm writes block YAML, while Nix writes a JSON overlay. This mixed
    // input combination produced flow YAML that yq accepted but kubelet rejected.
    const block = spawnSync("yq", ["-p=json", "-o=yaml", ".", base], { encoding: "utf8" });
    assert.equal(block.status, 0, block.stderr);
    assert.match(block.stdout, /^apiVersion:/);
    writeFileSync(base, block.stdout);
    assert.equal(run().status, 0);
    assert.deepEqual(decoded(), { ...original, ...settings });
    assert.equal(readFileSync(base, "utf8"), block.stdout);
    writeFileSync(overlay, JSON.stringify({ ...settings, podPidsLimit: 8192 }));
    assert.equal(run().status, 0);
    assert.equal(decoded().podPidsLimit, 8192);
    const good = readFileSync(output, "utf8");
    for (const invalid of ["{bad yaml", JSON.stringify({ ...original, authentication: { anonymous: { enabled: true } } }), JSON.stringify({ ...original, authorization: { mode: "AlwaysAllow" } })]) {
      writeFileSync(base, invalid);
      assert.notEqual(run().status, 0);
      assert.equal(readFileSync(output, "utf8"), good);
    }
    assert.notEqual(run(join(dir, "absent.yaml")).status, 0);
    writeFileSync(base, JSON.stringify(original));
    symlinkSync(base, join(dir, "base-link"));
    assert.notEqual(run(join(dir, "base-link")).status, 0);
    symlinkSync(output, join(dir, "output-link"));
    assert.notEqual(run(base, join(dir, "output-link")).status, 0);
    assert.equal(readFileSync(output, "utf8"), good);
    assert.deepEqual(readdirSync(dir).sort(), ["base-link", "config.yaml", "effective.yaml", "output-link", "overlay.json"]);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
