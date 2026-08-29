{ config, lib, ... }:
let
  inherit (lib.modules) mkDefault mkIf mkOverride;

  cfg = config.dsqr.nixos.kubeadm;
in
{
  imports = [
    ../observability/nixos.nix
    ../server/nixos.nix
  ];

  dsqr.nixos = {
    kubeadm.enable = true;

    # Cilium and Tailscale must share the iptables-nft compatibility layer.
    # NixOS still owns the host firewall through native nftables.
    tailscale.firewallMode = "iptables";

    alloy = {
      role = mkDefault (if cfg.role == null then "kubernetes" else "kubernetes-${cfg.role}");

      kubernetes.cluster = mkIf (cfg.cluster.name != null) (mkOverride 900 cfg.cluster.name);
    };
  };
}
