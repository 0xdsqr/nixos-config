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

  collectHostNix =
    {
      dir,
      ignoredNames ? [ ],
      ignoredFiles ? [ ],
    }:
    collectNix {
      inherit dir ignoredNames;
      ignoredFiles = [
        (dir + "/default.nix")
        (dir + "/meta.nix")
      ] ++ ignoredFiles;
    };

  nixosModuleInputNames = [ ];
  darwinModuleInputNames = [
    "nix-homebrew"
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
    let
      hostMeta = module.meta // { path = module.path; };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit self inputs;
        inherit (inputs) agenix nix-openclaw;
        inherit collectHostNix collectNix;
        hostName = name;
        inherit hostMeta;
      };

      modules = [
        module.path
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.default
        {
          _module.args = {
            inherit self inputs collectHostNix collectNix keys;
            meta = hostMeta;
            inherit hostMeta;
            ctx = {
              inherit self inputs collectHostNix collectNix keys hostMeta;
            };
          };
        }
      ]
      ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    name: system: module:
    let
      hostMeta = module.meta // { path = module.path; };
    in
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit self inputs;
        inherit (inputs) agenix nix-openclaw;
        inherit collectHostNix collectNix;
        hostName = name;
        inherit hostMeta;
      };

      modules = [
        module.path
        inputs.agenix.darwinModules.default
        inputs.home-manager.darwinModules.default
        {
          _module.args = {
            inherit self inputs collectHostNix collectNix keys;
            meta = hostMeta;
            inherit hostMeta;
            ctx = {
              inherit self inputs collectHostNix collectNix keys hostMeta;
            };
          };
        }
      ]
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
