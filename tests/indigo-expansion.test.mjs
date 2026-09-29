import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");

for (const [suffix, address] of [["04", "10.10.80.106"], ["05", "10.10.80.107"], ["06", "10.10.80.108"]]) {
  test(`worker-${suffix} retains the established Indigo baseline with a distinct identity`, () => {
    const name = `srv-lx-k8s-indigo-worker-${suffix}`;
    const source = read(`hosts/${name}/default.nix`);
    assert.ok(source.includes(`hostName = "${name}";`));
    assert.ok(source.includes(`sshHost = "${address}";`));
    assert.ok(source.includes(`nodeAddress = "${address}";`));
    assert.match(source, /role = "worker";/);
    assert.match(source, /profiles\/kubernetes\/nixos\.nix/);
    assert.match(source, /profiles\/kubernetes\/indigo-firewall\.nix/);
    assert.match(source, /ciliumProxyFirewall\.routingCompatibility\.enable = true;/);
    assert.match(source, /nodeFirewall\.enable = true;/);
    assert.match(source, /kubelet\.seccompDefault = true;/);
    assert.match(source, /apiEndpoint = "10\.10\.80\.10:6443";/);
    assert.match(source, /podSubnet = "10\.80\.0\.0\/16";/);
    assert.match(source, /serviceSubnet = "10\.81\.0\.0\/16";/);
    assert.match(source, /disableKubeProxy = true;/);
    assert.match(source, /tailscale\.enable = true;/);
    // Discover this machine's hardware at installation; never reuse another VM's report.
    assert.ok(source.includes(`hardware.report = ./${name}.report.json;`));
    assert.doesNotMatch(source, /bootstrap = true|indigo-encryption|indigo-backup/);
    assert.equal(read(`hosts/${name}/disk.nix`), read("hosts/srv-lx-k8s-indigo-worker-03/disk.nix"));
  });
}

test("new worker bootstrap secrets have distinct host identities and host-scoped recipients", () => {
  const keys = read("profiles/dsqr/keys.nix");
  const secrets = read("secrets.nix");
  const publicKeys = [];
  for (const suffix of ["04", "05", "06"]) {
    const name = `srv-lx-k8s-indigo-worker-${suffix}`;
    const match = keys.match(new RegExp(`${name} = "(ssh-ed25519 [^ ]+) root@${name}";`));
    assert.ok(match, `${name} must have its verified public host key`);
    publicKeys.push(match[1]);
    assert.ok(secrets.includes(`mkSecretsForHost "${name}" [ "hosts/${name}/tailscale.auth-key.age" ]`));
  }
  assert.equal(new Set(publicKeys).size, 3);
  assert.match(secrets, /forHost = name: \[ hosts\.\$\{name\} \] \+\+ admins;/);
});
