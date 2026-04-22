{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../keys.nix;
  inherit (self.lib) roost;
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
    name: system: module:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit (inputs) agenix nix-openclaw;
        inherit inputs roost;
        hostName = name;
      };

      modules = [
        module
        {
          _module.args = {
            inherit keys roost;
            ctx = { inherit keys roost; };
          };
        }
      ]
      ++ modulesCommon
      ++ modulesNixos
      ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    name: system: module:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit (inputs) agenix nix-openclaw;
        inherit inputs roost;
        hostName = name;
      };

      modules = [
        module
        {
          _module.args = {
            inherit keys roost;
            ctx = { inherit keys roost; };
          };
        }
      ]
      ++ modulesCommon
      ++ modulesDarwin
      ++ inputModulesDarwin;
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
        value = builder host.name host.meta.system host.path;
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
