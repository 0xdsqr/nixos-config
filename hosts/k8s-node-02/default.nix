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
    proxmox.enable = true;

    kubeadm.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
      role = "k8s-worker";
    };
  };

  networking = {
    hostName = "k8s-node-02";
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
