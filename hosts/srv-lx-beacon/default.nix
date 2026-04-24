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
  networking.hostName = "srv-lx-beacon";
  hardware.report = ./srv-lx-beacon.report.json;
  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/sda" ];
  };

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

  services.restic.passwordAgeFile = ./restic.password.age;
  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.firewall = {
    allowedTCPPorts = [
      8000
      9090
      3100
      1514
    ];
  };

  system.stateVersion = "25.05";
}
