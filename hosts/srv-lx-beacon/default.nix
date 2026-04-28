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
    sshHost = "10.10.30.102";
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
          "theme"
          "thunderbird"
          "web-browser"
        ] homeModules
      )
    );

  systemModules = modules ++ [
    nixosModules.restic
    ./alloy-opnsense.nix
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./tempo.nix
    {
      networking.hostName = "srv-lx-beacon";
      hardware.report = ./srv-lx-beacon.report.json;

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

      networking.firewall.allowedTCPPorts = [
        8000
        9090
        3100
        4317
        4318
        1514
      ];

      system.stateVersion = "25.05";
    }
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-beacon = hostMeta;

  flake.nixosConfigurations.srv-lx-beacon = self.lib.nixosSystem {
    hostName = "srv-lx-beacon";
    inherit hostMeta;
    modules = singleton ({ ... }: { imports = systemModules; });
  };

  flake.nixosConfigurations.srv-lx-beacon-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-beacon-installer";
    modules = singleton (
      { config, pkgs, ... }:
      let
        beacon = self.nixosConfigurations.srv-lx-beacon;
      in
      {
        imports = installerModules;

        networking.hostName = "srv-lx-beacon-installer";

        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
        isoImage.storeContents = singleton config.system.build.toplevel;

        hardware.enableAllHardware = true;

        environment.etc."install-closure".source = pkgs.closureInfo {
          rootPaths = [
            beacon.config.system.build.toplevel
            beacon.config.system.build.diskoScript
            beacon.config.system.build.diskoScript.drvPath
            beacon.pkgs.stdenv.drvPath
            (beacon.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
          ];
        };

        environment.systemPackages =
          singleton (
            pkgs.writeShellScriptBin "install-beacon" ''
              set -euo pipefail

              exec ${
                getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
              } --flake "${self}#srv-lx-beacon" --disk main "${beacon.config.disko.devices.disk.main.device}"
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
