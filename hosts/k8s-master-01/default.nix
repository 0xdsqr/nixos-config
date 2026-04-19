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
      remoteWriteUrl = "http://10.10.30.102:9090/api/v1/write";
      role = "k8s-control-plane";
      loki = {
        enable = true;
        writeUrl = "http://10.10.30.102:3100/loki/api/v1/push";
      };
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
