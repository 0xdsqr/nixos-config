{ dtil, ... }:
{
  imports = dtil.modules.collectNix {
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
      hostName = "khaos";
    };

    alloy = {
      enable = true;
      loki = {
        enable = true;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      5432
      9187
    ];
  };

  system.stateVersion = "25.05";
}
