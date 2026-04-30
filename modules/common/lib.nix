{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) singleton;

  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./keys.nix;

  inherit (self) commonModules;
  inherit (self) homeModules;
  inherit (self) darwinModules;
  inherit (self) nixosModules;

  darwinInputModules = [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.default
    inputs.nix-homebrew.darwinModules.default
  ];

  nixosInputModules = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.default
  ];

  commonSpecialArgs = {
    inherit self inputs keys;
    inherit
      commonModules
      homeModules
      darwinModules
      nixosModules
      ;
    inherit (inputs) agenix exo nix-openclaw;
    lib = nixLib;
  };
in
{
  flake.lib' = {
    inherit
      nixLib
      commonModules
      homeModules
      darwinModules
      nixosModules
      ;

    mkHostMeta =
      {
        class,
        path,
        system,
        sshHost ? null,
      }:
      {
        inherit
          class
          path
          sshHost
          system
          ;
      };

    mkHomeManagerSharedModule =
      selectedHomeModules:
      let
        inherit (nixLib.attrsets) attrValues;
        inherit (nixLib.modules) mkAfter;
      in
      {
        home-manager.sharedModules = mkAfter (attrValues selectedHomeModules);
      };

    darwinSystem =
      {
        hostName,
        hostMeta ? self.hostDefinitions.${hostName},
        modules,
      }:
      inputs.darwin.lib.darwinSystem {
        inherit (hostMeta) system;

        specialArgs = commonSpecialArgs // {
          inherit hostMeta hostName;
        };

        modules =
          modules ++ singleton { nixpkgs.hostPlatform = nixLib.modules.mkDefault hostMeta.system; } ++ darwinInputModules;
      };

    nixosSystem =
      {
        hostMeta,
        hostName,
        modules,
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit (hostMeta) system;

        specialArgs = commonSpecialArgs // {
          inherit hostMeta hostName;
        };

        modules = modules ++ nixosInputModules;
      };
  };

  flake.lib = recursiveUpdate lib self.lib';
}
