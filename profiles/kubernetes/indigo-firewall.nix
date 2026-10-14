{ config, lib, ... }:
let
  platformNodes = [
    "10.10.80.103"
    "10.10.80.104"
    "10.10.80.105"
  ];
  cfg = config.dsqr.nixos.kubeadm;
in
{
  # Cluster peer inventory is shared; individual hosts opt in after validation.
  # Keep API client access and Tailscale configuration outside this rollout.
  dsqr.nixos.kubeadm.nodeFirewall = {
    nodeAddresses = [
      "10.10.80.100"
      "10.10.80.101"
      "10.10.80.102"
      "10.10.80.103"
      "10.10.80.104"
      "10.10.80.105"
      "10.10.80.106"
      "10.10.80.107"
      "10.10.80.108"
    ];
    controlPlaneAddresses = [
      "10.10.80.100"
      "10.10.80.101"
      "10.10.80.102"
    ];
    memberlistAddresses = [
      "10.10.80.103"
      "10.10.80.104"
      "10.10.80.105"
      "10.10.80.106"
      "10.10.80.107"
      "10.10.80.108"
    ];
    podSubnets = [ "10.80.0.0/16" ];
    metrics = {
      enable = true;
      sourceNodeAddresses = platformNodes;
      # Live spec.podCIDR on platform workers 01–03, verified 2026-10-05.
      # Re-check these allocations after node replacement or pool expansion.
      sourcePodSubnets = [
        "10.80.3.0/24"
        "10.80.4.0/24"
        "10.80.5.0/24"
      ];
      tcpPorts = [
        9962
        9964
      ] # Cilium agent and Cilium Envoy on all nine nodes.
      ++ lib.optionals (cfg.role == "worker") [ 9120 ] # MetalLB speakers.
      ++ lib.optionals (builtins.elem cfg.nodeAddress platformNodes) [ 9963 ]; # Operator.
    };
  };
}
