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
  inherit (nixLib.trivial) flip;

  hostMeta = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.105";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      flip removeAttrs [ "containers" "monitoring-alloy-prometheus" "postgresql" "redis" "restic" "rustfs" ] nixosModules
    )
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        flip removeAttrs [
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
          "thunderbird"
          "web-browser"
        ] homeModules
      )
    );

  systemModules = modules ++ [
    {
      networking = {
        hostName = "srv-lx-k8s-node-01";
        domain = "dsqr.dev";
      };

      hardware.report = ./srv-lx-k8s-node-01.report.json;

      boot.loader.grub = {
        enable = true;
        devices = nixLib.mkForce [ "/dev/sda" ];
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

      dsqr.nixos.alloy.role = "k8s-worker";

      swapDevices = [ ];

      system.stateVersion = "25.05";
    }
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-k8s-node-01 = hostMeta;

  flake.nixosConfigurations.srv-lx-k8s-node-01 = self.lib.nixosSystem {
    hostName = "srv-lx-k8s-node-01";
    inherit hostMeta;
    modules = singleton (
      { ... }:
      {
        imports = systemModules;
      }
    );
  };

  flake.nixosConfigurations.srv-lx-k8s-node-01-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-k8s-node-01-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        node = self.nixosConfigurations.srv-lx-k8s-node-01;
      in
      {
        imports = installerModules;

        networking.hostName = "srv-lx-k8s-node-01-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            node.config.system.build.toplevel
            node.config.system.build.diskoScript
            node.config.system.build.diskoScript.drvPath
            node.pkgs.stdenv.drvPath
            (node.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-k8s-node-01" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-k8s-node-01" --disk main "${node.config.disko.devices.disk.main.device}"
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
