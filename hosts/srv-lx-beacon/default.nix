{
  commonModules,
  homeModules,
  nixosModules,
  lib,
  collectHostNix,
  ...
}:
let
  inherit (lib) mkAfter;
  inherit (lib.attrsets) attrValues removeAttrs;

  modules =
    attrValues commonModules
    ++ attrValues (
      removeAttrs nixosModules [
        "containers"
        "kubeadm"
        "monitoring-alloy-prometheus"
        "postgresql"
        "redis"
        "rustfs"
      ]
    )
    ++ [
      {
        home-manager.sharedModules = mkAfter (
          attrValues (
            removeAttrs homeModules [
              "aws"
              "bat"
              "cinny"
              "claude-code"
              "codex"
              "darwin-wm"
              "difftastic"
              "discord"
              "exo"
              "hammerspoon"
              "hushlogin"
              "ollama"
              "packages-containers"
              "packages-databases"
              "packages-debugging"
              "packages-kubernetes"
              "packages-media"
              "packages-node"
              "packages-signing"
              "opencode"
              "pi"
              "signal"
              "theme"
              "thunderbird"
              "web-browser"
            ]
          )
        );
      }
    ]
    ++ collectHostNix { dir = ./.; };
in
{
  meta.sshHost = "10.10.30.102";
  meta.system = "x86_64-linux";

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
