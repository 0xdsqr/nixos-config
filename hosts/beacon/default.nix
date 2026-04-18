{ lib, ... }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  services.restic.passwordAgeFile = ./restic.password.age;

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    proxmox.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://127.0.0.1:9090/api/v1/write";
      role = "beacon";
      loki = {
        enable = true;
        writeUrl = "http://127.0.0.1:3100/loki/api/v1/push";
      };
    };
  };

  networking.hostName = "beacon";
  networking.firewall.allowedTCPPorts = [
    8000
    9090
    3100
  ];
  networking.firewall.allowedUDPPorts = [ ];
  system.stateVersion = "25.05";
}
