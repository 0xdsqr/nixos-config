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
  inherit (nixLib.modules) mkForce;
  inherit (nixLib.trivial) flip;

  hostMeta = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.107";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (flip removeAttrs [ "containers" "iso" "kubeadm" "restic" ] nixosModules)
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
    self.nixosModules.restic
    ./alloy-postgres.nix
    ./postgresql.nix
    ./redis.nix
    ./rustfs.nix
    ./vault.nix
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-khaos = hostMeta;

  flake.nixosConfigurations.srv-lx-khaos = self.lib.nixosSystem {
    hostName = "srv-lx-khaos";
    inherit hostMeta;
    modules = singleton (
      { ... }:
      {
        imports = systemModules;

        allowedUnfreePackageNames = [ "vault-bin" ];

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
      }
    );
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
        imports = installerModules;

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
