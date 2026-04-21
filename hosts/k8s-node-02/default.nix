{ dtil, ... }:
{
  imports = dtil.modules.collectNix {
    dir = ./.;
    ignoredFiles = [
      ./default.nix
      ./meta.nix
    ];
  };

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
      hostName = "k8s-node-02";
    };

    kubeadm.enable = true;

    alloy = {
      enable = true;
      role = "k8s-worker";
      loki = {
        enable = true;
      };
    };
  };

  networking = {
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
