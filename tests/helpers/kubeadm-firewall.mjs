import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const root = new URL("../../", import.meta.url);
export const read = (path) => readFileSync(new URL(path, root), "utf8");
export const moduleSource = read("modules/nixos/kubeadm.nix");
const profile = read("profiles/kubernetes/indigo-firewall.nix");
export const inventory = Object.fromEntries(
  ["nodeAddresses", "controlPlaneAddresses", "memberlistAddresses", "podSubnets"].map((key) => {
    const value = profile.match(new RegExp(`${key} = \\[([^\\]]*)\\];`))?.[1];
    assert.ok(value, `Missing ${key}`);
    return [key, [...value.matchAll(/"([0-9./]+)"/g)].map((match) => match[1])];
  }),
);

// Extract the actual rule strings and substitute their four known inputs.
// This tests nft syntax/packet semantics without evaluating or building Nix;
// it does not claim to test the Nix module system or the activation process.
export function renderRules(role, nodeAddress) {
  const source = moduleSource.split("nodeFirewallRules = ")[1];
  const block = source.slice(0, source.indexOf("ciliumProxyRoutingRules ="));
  assert.match(block, /lib\.optionalString \(cfg\.role == "control-plane"\)/);
  assert.match(block, /lib\.optionalString \(builtins\.elem cfg\.nodeAddress cfg\.nodeFirewall\.memberlistAddresses\)/);
  const parts = [...block.matchAll(/''([\s\S]*?)''/g)].map((match) => match[1]);
  assert.equal(parts.length, 3);
  return [parts[0], role === "control-plane" ? parts[1] : "", inventory.memberlistAddresses.includes(nodeAddress) ? parts[2] : ""]
    .join("\n")
    .replace(/\$\{([\s\S]*?)\}/g, (_, expression) => {
      const normalized = expression.replace(/\s+/g, "");
      if (normalized === "firewallSources(cfg.nodeFirewall.nodeAddresses++cfg.nodeFirewall.podSubnets)") {
        return [...new Set([...inventory.nodeAddresses, ...inventory.podSubnets])].join(", ");
      }
      const key = normalized.match(/^firewallSourcescfg\.nodeFirewall\.(nodeAddresses|controlPlaneAddresses|memberlistAddresses)$/)?.[1];
      assert.ok(key, `Unrecognized Nix substitution: ${expression}`);
      return [...new Set(inventory[key])].join(", ");
    })
    .split("\n").map((line) => line.trim()).filter(Boolean).join("\n");
}

export function nftFixture() {
  return `table inet indigo_node_firewall_check {
    chain worker_input {\n${renderRules("worker", "10.10.80.105")}\n}
    chain control_input {\n${renderRules("control-plane", "10.10.80.100")}\n}
  }\n`;
}
