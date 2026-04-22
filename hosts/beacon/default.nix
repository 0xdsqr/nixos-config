{ roost, ... }:
{
  imports = roost.modules.collectNix {
    dir = ./.;
    ignoredFiles = [
      ./default.nix
      ./meta.nix
    ];
  };

  services.restic.passwordAgeFile = ./restic.password.age;

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
      hostName = "beacon";
    };

    alloy = {
      enable = true;
      loki.enable = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8000
      9090
      3100
      1514
    ];
  };

  system.stateVersion = "25.05";
}
