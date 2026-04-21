{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../keys.nix;
  inherit (self.lib) dtil;
  inherit (nixLib) evalModules;
  inherit (nixLib) mkOption;
  inherit (nixLib.types) enum nullOr str;

  modulesCommon = nixLib.attrValues self.commonModules;
  modulesNixos = nixLib.attrValues self.nixosModules;
  modulesDarwin = nixLib.attrValues self.darwinModules;
  nixosModuleInputNames = [
    "agenix"
    "home-manager"
    "sops-nix"
  ];

  darwinModuleInputNames = [
    "agenix"
    "home-manager"
    "nix-homebrew"
    "sops-nix"
  ];

  specialArgs = inputs // {
    inherit dtil inputs keys;
  };

  inputModulesNixos = builtins.map (name: inputs.${name}.nixosModules.default) nixosModuleInputNames;
  inputModulesDarwin = builtins.map (name: inputs.${name}.darwinModules.default) darwinModuleInputNames;

  hostMetaModule = {
    options = {
      class = mkOption {
        type = enum [
          "darwin"
          "nixos"
        ];
      };

      description = mkOption { type = str; };

      sshHost = mkOption {
        type = nullOr str;
        default = null;
      };

      system = mkOption { type = str; };
    };
  };

  mkNixosConfiguration =
    system: module:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;

      modules = [ module ] ++ modulesCommon ++ modulesNixos ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    system: module:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      inherit specialArgs;

      modules = [ module ] ++ modulesCommon ++ modulesDarwin ++ inputModulesDarwin;
    };

  hostNames = builtins.attrNames (builtins.readDir ./../hosts);

  hostDefinitions = builtins.map (
    name:
    let
      path = ./../hosts + "/${name}";
      rawMeta = import (path + "/meta.nix");
    in
    {
      inherit name path;
      meta =
        (evalModules {
          modules = [
            hostMetaModule
            rawMeta
          ];
        }).config;
    }
  ) hostNames;

  mkHostConfigurations =
    class: builder:
    builtins.listToAttrs (
      builtins.map (host: {
        inherit (host) name;
        value = builder host.meta.system host.path;
      }) (builtins.filter (host: host.meta.class == class) hostDefinitions)
    );
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

    nixosConfigurations = mkHostConfigurations "nixos" mkNixosConfiguration;
    darwinConfigurations = mkHostConfigurations "darwin" mkDarwinConfiguration;
  };
}
