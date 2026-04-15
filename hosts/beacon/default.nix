{ keys, lib, ... }:
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
      remoteWriteUrl = "http://127.0.0.1:9090/api/v1/write";
      role = "beacon";
    };
  };

  networking.hostName = "beacon";
  networking.firewall.allowedTCPPorts = [
    8000
    9090
    3100
  ];
  networking.firewall.allowedUDPPorts = [ ];

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    extraGroups = [
      "docker"
      "lxd"
      "wheel"
      "networkmanager"
    ];
    description = "its me dave";
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = keys.admins;
  };

  system.stateVersion = "25.05";
}
