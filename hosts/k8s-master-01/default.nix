{ dtil, ... }:
{
  imports = dtil.modules.collectLocalNixModules { dir = ./.; };

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    # this host runs as a proxmox vm; enable the shared guest baseline
    # for grub boot, qemu guest agent, cloud-init disablement, and dhcp defaults.
    proxmox = {
      enable = true;
      hostName = "k8s-master-01";
    };

    kubeadm.enable = true;

    alloy = {
      enable = true;
      role = "k8s-control-plane";
      loki = {
        enable = true;
      };
      kubernetes = {
        enable = true;

        kubeStateMetrics.enable = true;
      };
    };
  };

  networking = {
    domain = "dsqr.dev";
    firewall = {
      allowedTCPPorts = [
        22
        6443
        2379
        2380
        10250
        10257
        10259
      ];
    };
  };

  system.stateVersion = "25.05";
}
