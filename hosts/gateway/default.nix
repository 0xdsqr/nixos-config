{ lib, ... }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    # this host runs as a proxmox vm; enable the shared guest baseline
    # for grub boot, qemu guest agent, cloud-init disablement, and dhcp defaults.
    proxmox.enable = true;

    # this uses our custom module because the tunnel is remotely managed
    # and token-based rather than a local credentials-file setup.
    cloudflared = {
      enable = true;
      tunnelId = "9c851b2c-8644-40a5-8cf4-ae7f63f4a20c";
      tunnelName = "gateway";
      tokenAgeFile = ./cloudflared.token.age;
    };

    alloy = {
      enable = true;
      remoteWriteUrl = "http://10.10.30.102:9090/api/v1/write";
      loki = {
        enable = true;
        writeUrl = "http://10.10.30.102:3100/loki/api/v1/push";
      };
    };
  };

  networking = {
    hostName = "gateway";
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  system.stateVersion = "25.05";
}
