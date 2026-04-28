{ self, inputs, ... }:
let
  inherit (self.lib)
    commonModules
    homeModules
    nixLib
    nixosModules
    ;
  inherit (nixLib.attrsets) attrValues removeAttrs;
  inherit (nixLib.lists) singleton;
  inherit (nixLib.meta) getExe;

  hostMeta = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "178.156.204.203";
    system = "x86_64-linux";
  };

  baseModules =
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
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        removeAttrs homeModules [
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

  modules = baseModules ++ [
    ./stalwart.nix
    {
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
  ];
in
{
  flake.hostDefinitions.srv-lx-mailbox = hostMeta;

  flake.nixosConfigurations.srv-lx-mailbox = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-mailbox";
  };

  flake.nixosConfigurations.srv-lx-mailbox-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-mailbox-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        mailbox = self.nixosConfigurations.srv-lx-mailbox;
      in
      {
        imports = baseModules ++ singleton (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix);

        networking.hostName = "srv-lx-mailbox-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            mailbox.config.system.build.toplevel
            mailbox.config.system.build.diskoScript
            mailbox.config.system.build.diskoScript.drvPath
            mailbox.pkgs.stdenv.drvPath
            (mailbox.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-mailbox" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-mailbox" --disk main "${mailbox.config.disko.devices.disk.main.device}"
            ''
          )
          ++ singleton (
            pkgs.writeShellScriptBin "generate-facter-report" ''
              set -euo pipefail

              exec ${getExe pkgs.nixos-facter}
            ''
          );

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "25.11";
      }
    );
  };
}
