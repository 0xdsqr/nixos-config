{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkForce;

  hostMeta = {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.108";
    system = "x86_64-linux";
  };

  baseModules =
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
      home-manager.sharedModules = mkAfter (
        attrValues (
          removeAttrs self.homeModules [
            "aws"
            "bat"
            "cinny"
            "claude-code"
            "codex"
            "window-manager"
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
    };

  modules = singleton {
    imports =
      baseModules
      ++ singleton ./openclaw/default.nix;

    networking.hostName = "srv-lx-hoo";
    hardware.report = ./srv-lx-hoo.report.json;

    boot.loader.grub = {
      enable = true;
      devices = mkForce [ "/dev/sda" ];
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
            size = "100%";
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

    system.stateVersion = "25.05";
  };
in
{
  flake.hostDefinitions.srv-lx-hoo = hostMeta;

  flake.nixosConfigurations.srv-lx-hoo = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-hoo";
  };

  flake.nixosConfigurations.srv-lx-hoo-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-hoo-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        hoo = self.nixosConfigurations.srv-lx-hoo;
      in
      {
        imports = baseModules ++ singleton (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix);

        networking.hostName = "srv-lx-hoo-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            hoo.config.system.build.toplevel
            hoo.config.system.build.diskoScript
            hoo.config.system.build.diskoScript.drvPath
            hoo.pkgs.stdenv.drvPath
            (hoo.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-hoo" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-hoo" --disk main "${hoo.config.disko.devices.disk.main.device}"
            ''
          )
          ++ singleton (
            pkgs.writeShellScriptBin "generate-facter-report" ''
              set -euo pipefail

              exec ${getExe pkgs.nixos-facter}
            ''
          );

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "25.05";
      }
    );
  };
}
