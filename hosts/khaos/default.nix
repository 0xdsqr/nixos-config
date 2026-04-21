{ dtil, pkgs, ... }:
{
  imports = dtil.modules.collectLocalNixModules { dir = ./.; };

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
    allowedUDPPorts = [ ];
  };

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  system.stateVersion = "25.05";
}
