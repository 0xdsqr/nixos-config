{
  self,
  inputs,
  ...
}:
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
    sshHost = "10.10.30.108";
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
    inputs.hoo.nixosModules.hoo
    ./openclaw/default.nix
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-hoo = hostMeta;

  flake.nixosConfigurations.srv-lx-hoo = self.lib.nixosSystem {
    hostName = "srv-lx-hoo";
    inherit hostMeta;
    modules = singleton (
      { config, ... }:
      {
        imports = systemModules;

        networking.hostName = "srv-lx-hoo";
        hardware.report = ./srv-lx-hoo.report.json;

        age.secrets.githubDeployKey = {
          file = ./github.deploy-key.age;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        services.hoo.api-server = {
          enable = true;
          host = "0.0.0.0";
          port = 9321;
        };

        networking.firewall.allowedTCPPorts = [ 9321 ];

        home-manager.users.dsqr.imports = [
          inputs.hoo.homeManagerModules.hoo
          {
            programs.hoo.enable = true;
          }
        ];

        programs.ssh.extraConfig = ''
          Host github.com
            User git
            IdentityFile ${config.age.secrets.githubDeployKey.path}
            IdentitiesOnly yes
            StrictHostKeyChecking accept-new
        '';

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
      }
    );
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
        imports = installerModules;

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
