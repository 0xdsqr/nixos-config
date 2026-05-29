{ inputs, ... }:
{
  flake.commonModules.nix =
    {
      config,
      hostMeta ? null,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrs
        mapAttrsToList
        optionalAttrs
        ;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.types)
        anything
        attrsOf
        bool
        listOf
        package
        isType
        ;

      cfg = config.dsqr.nix;
      registryMap = filterAttrs (_: isType "flake") inputs;
      isDarwinHost = hostMeta != null && hostMeta.class == "darwin";
      managesNix = hostMeta != null && hostMeta.class == "nixos";
      registryPathEntries = mapAttrsToList (name: value: "${name}=${value}") registryMap;
    in
    {
      options.dsqr.nix = {
        enable = mkEnableOption "shared Nix configuration";

        channel.enable = mkOption {
          type = bool;
          default = false;
          description = "Whether to keep Nix channels enabled.";
        };

        distributedBuilds = mkOption {
          type = bool;
          default = false;
          description = "Whether to enable distributed Nix builds.";
        };

        buildMachines = mkOption {
          type = listOf (attrsOf anything);
          default = [ ];
          description = "Nix build machines.";
        };

        settings = mkOption {
          type = attrsOf anything;
          default = { };
          description = "Nix daemon/client settings.";
        };

        systemPackages = mkOption {
          type = listOf package;
          default = with pkgs; [
            nh
            nix-index
            nix-output-monitor
          ];
          description = "Packages installed alongside the shared Nix configuration.";
        };

        package = mkOption {
          type = package;
          default = pkgs.nixVersions.latest;
          defaultText = "pkgs.nixVersions.latest";
          description = "Nix package used on NixOS hosts managed by this module.";
        };

        registry.enable = mkEnableOption "flake registry entries for flake inputs" // {
          default = true;
        };

        nixPath.enable = mkEnableOption "NIX_PATH entries for flake inputs" // {
          default = true;
        };

        gc.enable = mkEnableOption "automatic Nix garbage collection" // {
          default = managesNix;
        };

        optimise.enable = mkEnableOption "automatic Nix store optimisation" // {
          default = managesNix;
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = cfg.systemPackages;

        nix = {
          channel.enable = cfg.channel.enable;

          inherit (cfg) settings;
          inherit (cfg) distributedBuilds;
          inherit (cfg) buildMachines;

          registry = mkIf cfg.registry.enable (
            mapAttrs (_: flake: { inherit flake; }) (registryMap // { default = inputs.nixpkgs; })
          );
        }
        // optionalAttrs cfg.nixPath.enable {
          nixPath = if isDarwinHost then concatStringsSep ":" registryPathEntries else registryPathEntries;
        }
        // optionalAttrs (managesNix && cfg.gc.enable) {
          gc = {
            automatic = true;
            options = "--delete-older-than 3d";
            dates = "weekly";
            persistent = true;
          };
        }
        // optionalAttrs managesNix {
          optimise.automatic = cfg.optimise.enable;
          inherit (cfg) package;
        };
      };
    };
}
