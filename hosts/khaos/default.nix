{ pkgs, lib, ... }:
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
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
      loki = {
        enable = true;
        writeUrl = "http://192.168.50.70:3100/loki/api/v1/push";
      };
    };
  };

  networking.hostName = "khaos";
  networking.firewall.allowedTCPPorts = [
    5432
    9187
  ];
  networking.firewall.allowedUDPPorts = [ ];

  environment.systemPackages = [ pkgs.ghostty.terminfo ];
  system.stateVersion = "25.05";
}
