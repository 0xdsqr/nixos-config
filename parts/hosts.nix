{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../keys.nix;
  inherit (nixLib) evalModules;
  inherit (nixLib.filesystem) listFilesRecursive;
  inherit (nixLib.lists) elem filter;
  inherit (nixLib) mkOption;
  inherit (nixLib.strings) hasSuffix;
  inherit (nixLib.types) enum nullOr str;

  collectNix =
    {
      dir,
      ignoredNames ? [ ],
      ignoredFiles ? [ ],
    }:
    filter (
      path:
      let
        name = builtins.baseNameOf path;
      in
      hasSuffix ".nix" path && !(elem name ignoredNames) && !(elem path ignoredFiles)
    ) (listFilesRecursive dir);

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

      profile = mkOption {
        type = nullOr (enum [
          "darwin-laptop-aarch64"
          "darwin-mini-aarch64"
          "linux-desktop-aarch64"
          "linux-desktop-x86_64"
          "linux-vm-aarch64"
          "linux-vm-x86_64"
        ]);
        default = null;
      };

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
        inherit collectNix inputs;
        hostName = name;
        hostMeta = module.meta;
      };

      modules = [
        module.path
        {
          _module.args = {
            inherit collectNix keys;
            inherit (module) meta;
            hostMeta = module.meta;
            ctx = {
              inherit collectNix keys;
              hostMeta = module.meta;
            };
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
        inherit collectNix inputs;
        hostName = name;
        hostMeta = module.meta;
      };

      modules = [
        module.path
        {
          _module.args = {
            inherit collectNix keys;
            inherit (module) meta;
            hostMeta = module.meta;
            ctx = {
              inherit collectNix keys;
              hostMeta = module.meta;
            };
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
        value = builder host.name host.meta.system host;
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
