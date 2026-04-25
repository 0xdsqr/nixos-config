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
  meta.sshHost = "178.156.204.203";
  meta.system = "x86_64-linux";

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
