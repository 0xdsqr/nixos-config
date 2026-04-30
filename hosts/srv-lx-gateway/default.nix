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
    sshHost = "10.10.60.100";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      flip removeAttrs [
        "containers"
        "kubeadm"
        "monitoring-alloy-prometheus"
        "postgresql"
        "redis"
        "restic"
        "rustfs"
      ] nixosModules
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
    ./alloy-cloudflared.nix
    ./cloudflared.nix
    {
      networking.hostName = "srv-lx-gateway";
      hardware.report = ./srv-lx-gateway.report.json;

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

      swapDevices = [ ];

      system.stateVersion = "25.05";
    }
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-gateway = hostMeta;

  flake.nixosConfigurations.srv-lx-gateway = self.lib.nixosSystem {
    hostName = "srv-lx-gateway";
    inherit hostMeta;
    modules = singleton (
      { ... }:
      {
        imports = systemModules;
      }
    );
  };

  flake.nixosConfigurations.srv-lx-gateway-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-gateway-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        gateway = self.nixosConfigurations.srv-lx-gateway;
      in
      {
        imports = installerModules;

        networking.hostName = "srv-lx-gateway-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            gateway.config.system.build.toplevel
            gateway.config.system.build.diskoScript
            gateway.config.system.build.diskoScript.drvPath
            gateway.pkgs.stdenv.drvPath
            (gateway.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-gateway" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-gateway" --disk main "${gateway.config.disko.devices.disk.main.device}"
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
