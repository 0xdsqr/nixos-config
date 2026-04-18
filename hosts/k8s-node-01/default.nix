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

    proxmox.enable = true;

    kubeadm.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
      role = "k8s-worker";
      loki = {
        enable = true;
        writeUrl = "http://192.168.50.70:3100/loki/api/v1/push";
      };
    };
  };

  networking = {
    hostName = "k8s-node-01";
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
