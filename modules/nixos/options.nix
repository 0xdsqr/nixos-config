{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.dsqr.nixos = {
    proxmox = {
      enable = mkEnableOption "Enable Proxmox-based host leveraging NixOS";
    };

    alloy = {
      enable = mkEnableOption "Enable Alloy-based host monitoring on NixOS hosts";

      instance = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "Stable instance label for this host";
      };

      role = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "Role label for this host";
      };

      environment = mkOption {
        type = types.str;
        default = "homelab";
        description = "Environment label for this host";
      };

      remoteWriteUrl = mkOption {
        type = types.str;
        description = "Prometheus remote_write receiver URL on beacon";
      };
    };

    postgresql = {
      enable = mkEnableOption "Enable the shared PostgreSQL host profile";

      ensure = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Databases and matching users to create automatically.";
      };

    };
  };
}
