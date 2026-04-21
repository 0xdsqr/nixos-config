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
    proxmox = {
      enable = true;
      hostName = "k8s-node-02";
    };

    kubeadm.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://10.10.30.102:9090/api/v1/write";
      role = "k8s-worker";
      loki = {
        enable = true;
        writeUrl = "http://10.10.30.102:3100/loki/api/v1/push";
      };
    };
  };

  networking = {
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
