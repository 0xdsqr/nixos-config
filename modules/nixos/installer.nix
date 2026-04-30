{ inputs, self, ... }:
{
  flake.nixosModules.installer =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.lists) optionals singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) removePrefix;
      inherit (lib.types) bool nullOr str;

      cfg = config.dsqr.nixos.installer;
    in
    {
      options.dsqr.nixos.installer = {
        enable = mkEnableOption "NixOS installer ISO support";

        targetHostName = mkOption {
          type = nullOr str;
          default = null;
          description = "NixOS configuration name to install from this ISO.";
        };

        hostName = mkOption {
          type = nullOr str;
          default = null;
          description = "Installer host name.";
        };

        hostPlatform = mkOption {
          type = str;
          default = "x86_64-linux";
          description = "Installer host platform.";
        };

        diskName = mkOption {
          type = str;
          default = "main";
          description = "Disko disk name to pass to disko-install.";
        };

        commandName = mkOption {
          type = nullOr str;
          default = null;
          description = "Installer command name. Defaults to install-<target without srv-lx->.";
        };

        efiBootable = mkOption {
          type = bool;
          default = true;
          description = "Whether to make the installer ISO EFI bootable.";
        };

        usbBootable = mkOption {
          type = bool;
          default = true;
          description = "Whether to make the installer ISO USB bootable.";
        };

        enableAllHardware = mkOption {
          type = bool;
          default = true;
          description = "Whether to enable all hardware support in the installer ISO.";
        };

        facter.enable = mkEnableOption "generate-facter-report helper" // {
          default = true;
        };
      };

      config = mkIf cfg.enable (
        let
          target = self.nixosConfigurations.${cfg.targetHostName};
          installCommandName =
            if cfg.commandName == null then "install-${removePrefix "srv-lx-" cfg.targetHostName}" else cfg.commandName;
          targetDisk = target.config.disko.devices.disk.${cfg.diskName}.device;
        in
        {
          assertions = singleton {
            assertion = cfg.targetHostName != null;
            message = "dsqr.nixos.installer.targetHostName must be set when dsqr.nixos.installer.enable is true.";
          };

          hardware.enableAllHardware = cfg.enableAllHardware;
          nixpkgs.hostPlatform = cfg.hostPlatform;

          networking.hostName = mkIf (cfg.hostName != null) cfg.hostName;

          dsqr.nixos = {
            fonts.enable = true;
            openssh.enable = true;
            tailscale.enable = true;
            user.enable = true;
          };

          environment.etc."install-closure".source = pkgs.closureInfo {
            rootPaths = [
              target.config.system.build.toplevel
              target.config.system.build.diskoScript
              target.config.system.build.diskoScript.drvPath
              target.pkgs.stdenv.drvPath
              (target.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
            ];
          };

          environment.systemPackages =
            singleton (
              pkgs.writeShellScriptBin installCommandName /* bash */ ''
                set -euo pipefail

                exec ${
                  getExe inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
                } --flake "${self}#${cfg.targetHostName}" --disk "${cfg.diskName}" "${targetDisk}"
              ''
            )
            ++ optionals cfg.facter.enable (
              singleton (
                pkgs.writeShellScriptBin "generate-facter-report" /* bash */ ''
                  set -euo pipefail

                  exec ${getExe pkgs.nixos-facter}
                ''
              )
            );
        }
        // optionalAttrs (options ? isoImage) {
          isoImage.makeEfiBootable = cfg.efiBootable;
          isoImage.makeUsbBootable = cfg.usbBootable;
          isoImage.storeContents = singleton config.system.build.toplevel;
        }
      );
    };
}
