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
        "monitoring-alloy-prometheus"
        "postgresql"
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
  networking.hostName = "srv-lx-hoo";
  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/sda" ];
  };
  hardware.report = ./srv-lx-hoo.report.json;

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

        root = {
          end = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.05";
}
