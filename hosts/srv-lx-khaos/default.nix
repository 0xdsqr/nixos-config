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
    sshHost = "10.10.30.107";
    system = "x86_64-linux";
  };

  baseModules =
    attrValues self.commonModules
    ++ attrValues (
      removeAttrs self.nixosModules [
        "containers"
        "iso"
        "kubeadm"
        "restic"
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
      ++ singleton self.nixosModules.restic
      ++ singleton ../lib/build-user.nix
      ++ singleton ./alloy-postgres.nix
      ++ singleton ./postgresql.nix
      ++ singleton ./redis.nix
      ++ singleton ./rustfs.nix
      ++ singleton ./vault.nix;

    networking.hostName = "srv-lx-khaos";
    hardware.report = ./srv-lx-khaos.report.json;

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

    networking.firewall.allowedTCPPorts = [ 5432 ];

    system.stateVersion = "25.05";
  };
in
{
  flake.hostDefinitions.srv-lx-khaos = hostMeta;

  flake.nixosConfigurations.srv-lx-khaos = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-khaos";
  };

  flake.nixosConfigurations.srv-lx-khaos-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-khaos-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        khaos = self.nixosConfigurations.srv-lx-khaos;
      in
      {
        imports = baseModules ++ singleton (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix);

        networking.hostName = "srv-lx-khaos-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            khaos.config.system.build.toplevel
            khaos.config.system.build.diskoScript
            khaos.config.system.build.diskoScript.drvPath
            khaos.pkgs.stdenv.drvPath
            (khaos.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-khaos" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-khaos" --disk main "${khaos.config.disko.devices.disk.main.device}"
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
