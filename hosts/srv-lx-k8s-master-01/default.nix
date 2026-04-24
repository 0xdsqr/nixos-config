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
  networking.hostName = "srv-lx-k8s-master-01";
  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/sda" ];
  };
  hardware.report = ./srv-lx-k8s-master-01.report.json;

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

  dsqr.nixos = {
    alloy = {
      role = "k8s-control-plane";
      kubernetes = {
        kubeconfigFile = "/etc/kubernetes/admin.conf";
      };
    };
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking = {
    domain = "dsqr.dev";
    firewall = {
      allowedTCPPorts = [
        22
        6443
        2379
        2380
        10250
        10257
        10259
      ];
    };
  };

  system.stateVersion = "25.05";
}
