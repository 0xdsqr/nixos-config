{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  dsqr.nixos = {
    proxmox.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
    };
  };

  networking.hostName = "khaos";
  networking.firewall.allowedTCPPorts = [
    5432
    9187
  ];
  networking.firewall.allowedUDPPorts = [ ];

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  users.users.dsqr.extraGroups = [
    "docker"
    "lxd"
    "wheel"
    "networkmanager"
  ];

  system.stateVersion = "25.05";
}
