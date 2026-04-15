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

    kubeadm.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
    };
  };

  networking = {
    hostName = "k8s-master-01";
    domain = "dsqr.dev";
    firewall.allowedTCPPorts = [
      22
      6443
      2379
      2380
      10250
      10257
      10259
    ];
  };

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    description = "its me dave";
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = keys.admins;
  };

  system.stateVersion = "25.05";
}
