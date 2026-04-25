{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  collectors = import ./../lib/collectors.nix nixLib;
  keys = import ./../keys.nix;
  inherit (nixLib) evalModules mkOption;
  inherit (nixLib.strings) hasSuffix;
  inherit (nixLib.types) nullOr str;
  inherit (collectors) collectHostNix collectNix;

  nixosModuleInputNames = [ ];
  darwinModuleInputNames = [ "nix-homebrew" ];
  inputModulesNixos = builtins.map (name: inputs.${name}.nixosModules.default) nixosModuleInputNames;
  inputModulesDarwin = builtins.map (name: inputs.${name}.darwinModules.default) darwinModuleInputNames;

  hostMetaModule = {
    options = {
      sshHost = mkOption {
        type = nullOr str;
        default = null;
      };

      system = mkOption { type = str; };
    };
  };

  themeFlakeModule = import ./../modules/theme.nix { inherit self; };
  unfreeFlakeModule = import ./../modules/unfree.nix;
  nixosFontsFlakeModule = import ./../modules/nixos/fonts.nix;
  packagesFlakeModule = import ./../modules/packages.nix;
  profiles = import ./../lib/profiles.nix {
    inherit darwinModules homeModules;
    lib = nixLib;
  };

  commonModules = {
    "home-manager" = (import ./../modules/home-manager.nix { inherit self inputs; }).flake.commonModules."home-manager";

    inherit ((import ./../modules/nix.nix { inherit inputs; }).flake.commonModules) nix;
    inherit ((import ./../modules/nixpkgs.nix { inherit inputs; }).flake.commonModules) nixpkgs;
    inherit (themeFlakeModule.flake.commonModules) theme;
    inherit (unfreeFlakeModule.flake.commonModules) unfree;
  };

  homeModules = self.homeModules // {
    inherit (commonModules) theme;
  };

  darwinModules = self.darwinModules // {
    inherit (packagesFlakeModule.flake.darwinModules) packages;
  };

  nixosModules = self.nixosModules // {
    inherit (nixosFontsFlakeModule.flake.nixosModules) fonts;
  };

  hostModuleArgs = {
    inherit
      self
      inputs
      collectors
      collectHostNix
      collectNix
      commonModules
      homeModules
      darwinModules
      nixosModules
      profiles
      ;
    lib = nixLib;
  };
  systems = import ./../lib/systems.nix {
    inherit
      collectors
      collectHostNix
      collectNix
      commonModules
      darwinModules
      homeModules
      inputModulesDarwin
      inputModulesNixos
      inputs
      keys
      nixLib
      nixosModules
      profiles
      self
      ;
  };
  inherit (systems) mkDarwinConfiguration mkHostConfigurations mkNixosConfiguration;

  hostNames = builtins.attrNames (builtins.readDir ./../hosts);

  hostDefinitions = builtins.map (
    name:
    let
      path = ./../hosts + "/${name}";
      rawHost = import (path + "/default.nix") hostModuleArgs;
      meta =
        (evalModules {
          modules = [
            hostMetaModule
            rawHost.meta
          ];
        }).config;
      class = if hasSuffix "-darwin" meta.system then "darwin" else "nixos";
    in
    {
      inherit name path;
      module = builtins.removeAttrs rawHost [ "meta" ];
      meta = meta // {
        inherit class;
      };
    }
  ) hostNames;
in
{
  flake = {
    hostDefinitions = builtins.listToAttrs (
      builtins.map (host: {
        inherit (host) name;
        value = host.meta // {
          inherit (host) path;
        };
      }) hostDefinitions
    );

    nixosConfigurations = mkHostConfigurations "nixos" mkNixosConfiguration hostDefinitions;
    darwinConfigurations = mkHostConfigurations "darwin" mkDarwinConfiguration hostDefinitions;
  };
}
