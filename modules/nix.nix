{ inputs, self, ... }:
{
  flake.commonModules.nix =
    {
      hostMeta ? null,
      hostName,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrs mapAttrsToList optionalAttrs removeAttrs;
      inherit (lib.lists) optional;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.types) isType;

      registryMap = filterAttrs (_: isType "flake") (removeAttrs inputs [ "hoo" ]);
      isDarwinHost = hostMeta != null && hostMeta.class == "darwin";
      managesNix = hostMeta != null && hostMeta.class == "nixos";
      registryPathEntries = mapAttrsToList (name: value: "${name}=${value}") registryMap;
      builderHostName = "srv-lx-khaos";
      builderPublicHostKey = "AAAAC3NzaC1lZDI1NTE5AAAAIO96/hopscQBRbeWkv6CCcCNpe/5lwYt13c3bEWBDkyD";
      builderHost =
        if builtins.hasAttr builderHostName self.hostDefinitions then self.hostDefinitions.${builderHostName} else null;

      rootNixSettings =
        removeAttrs (import (self + /flake.nix)).nixConfig (
          [
            "extra-substituters"
            "extra-trusted-public-keys"
          ]
          ++ optional isDarwinHost "use-cgroups"
        )
        // {
          substituters = [
            "https://cache.nixos.org/"
            "https://exo.cachix.org"
          ];

          trusted-public-keys = [ "exo.cachix.org-1:okq7hl624TBeAR3kV+g39dUFSiaZgLRkLsFBCuJ2NZI=" ];
        };

      builderMachines =
        optional
          (
            managesNix
            && builderHost != null
            && hostName != builderHostName
          )
          {
            hostName = if builderHost.sshHost == null then builderHostName else builderHost.sshHost;
            maxJobs = 20;
            publicHostKey = builderPublicHostKey;
            protocol = "ssh-ng";
            sshUser = "build";
            supportedFeatures = [
              "big-parallel"
              "kvm"
            ];
            system = "x86_64-linux";
          };
    in
    {
      config = {
        environment.systemPackages = with pkgs; [
          nh
          nix-index
          nix-output-monitor
        ];

        nix = {
          channel.enable = false;

          settings = rootNixSettings // {
            builders-use-substitutes = true;
          };
          distributedBuilds = true;
          buildMachines = builderMachines;

          registry = mapAttrs (_: flake: { inherit flake; }) (registryMap // { default = inputs.nixpkgs; });

          nixPath = if isDarwinHost then concatStringsSep ":" registryPathEntries else registryPathEntries;
        }
        // optionalAttrs managesNix {
          gc = {
            automatic = true;
            options = "--delete-older-than 3d";
            dates = "weekly";
            persistent = true;
          };

          optimise.automatic = true;
          package = pkgs.nixVersions.latest;
        };
      };
    };
}
