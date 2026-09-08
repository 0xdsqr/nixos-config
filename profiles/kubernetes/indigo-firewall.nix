{ ... }:
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
    ];
    podSubnets = [ "10.80.0.0/16" ];
  };
}
