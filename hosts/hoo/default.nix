{ collectNix, ... }:
{
  imports = collectNix {
    dir = ./.;
    ignoredFiles = [
      ./default.nix
      ./meta.nix
      ./openclaw/hoo.nix
      ./openclaw/plugins.nix
      ./openclaw/vanilla.nix
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
      hostName = "hoo";
    };

    alloy = {
      enable = true;
      loki.enable = true;
    };
  };

  system.stateVersion = "25.05";
}
