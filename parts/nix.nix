{ inputs, ... }:
{
  flake.commonModules.nix =
    { lib, pkgs, ... }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrs
        mapAttrsToList
        optionalAttrs
        ;
      inherit (lib) pipe;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.trivial) id;
      inherit (lib.types) isType;

      registryMap = filterAttrs (_: isType "flake") inputs;
      managesNix = pkgs.stdenv.hostPlatform.isLinux;
    in
    {
      environment.systemPackages = with pkgs; [
        nh
        nix-index
        nix-output-monitor
      ];

      nix = {
        channel.enable = false;

        settings.experimental-features = [
          "flakes"
          "nix-command"
        ];

        registry = mapAttrs (_: flake: { inherit flake; }) (registryMap // { default = inputs.nixpkgs; });

        nixPath = pipe registryMap [
          (mapAttrsToList (name: value: "${name}=${value}"))
          (if pkgs.stdenv.hostPlatform.isDarwin then concatStringsSep ":" else id)
        ];
      }
      // optionalAttrs managesNix {
        gc = {
          automatic = true;
          options = "--delete-older-than 3d";
        }
        // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          dates = "weekly";
          persistent = true;
        }
        // optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          interval = [
            {
              Hour = 3;
              Minute = 15;
              Weekday = 7;
            }
          ];
        };

        optimise.automatic = true;
        package = pkgs.nixVersions.latest;
      };
    };
}
