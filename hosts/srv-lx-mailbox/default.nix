{
  self,
  lib,
  collectHostNix,
  ...
}:
let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) singleton;

  modules =
    attrValues self.commonModules
    ++ attrValues (
      removeAttrs self.nixosModules [
        "containers"
        "kubeadm"
        "monitoring-alloy-base"
        "monitoring-alloy-loki"
        "monitoring-alloy-prometheus"
        "postgresql"
        "proxmox"
        "redis"
        "restic"
        "rustfs"
      ]
    )
    ++ singleton {
      home.extraModules = attrValues (
        removeAttrs self.homeModules [
          "tmux"
          "zsh"
        ]
      );
    }
    ++ collectHostNix { dir = ./.; };
in
{
  imports = modules;

  networking.hostName = "srv-lx-mailbox";
  hardware.report = ./srv-lx-mailbox.report.json;

  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };

        ESP = {
          end = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          end = "-0";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  services.tailscale = {
    useRoutingFeatures = "client";
    extraUpFlags = [ "--ssh" ];
  };

  services.openssh.openFirewall = true;

  boot.kernelParams = [ "console=ttyS0,115200" ];
  boot.loader.grub.enable = true;

  system.stateVersion = "25.11";
}
