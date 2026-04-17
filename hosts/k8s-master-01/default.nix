{ config, keys, lib, ... }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  age.secrets.hostPassword.file = ./password.age;

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    description = "its me dave";
    hashedPasswordFile = config.age.secrets.hostPassword.path;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = keys.admins;
  };

  users.users.root.hashedPasswordFile = config.age.secrets.hostPassword.path;

  dsqr.nixos = {
    proxmox.enable = true;

    kubeadm.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://192.168.50.70:9090/api/v1/write";
      role = "k8s-control-plane";
      kubernetes = {
        enable = true;

        kubeStateMetrics.enable = true;
      };
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

  system.stateVersion = "25.05";
}
