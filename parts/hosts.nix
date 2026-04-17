{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../keys.nix;

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
    inherit inputs keys self;
  };

  inputModulesNixos = builtins.map (name: inputs.${name}.nixosModules.default) nixosModuleInputNames;
  inputModulesDarwin = builtins.map (name: inputs.${name}.darwinModules.default) darwinModuleInputNames;

  mkNixosConfiguration =
    system: module:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;

      modules = [
        module
        self.commonModules.sharedNixpkgs
        self.commonModules.sharedHomeManager
      ]
      ++ modulesNixos
      ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    system: module:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      inherit specialArgs;

      modules = [
        module
        self.commonModules.sharedNixpkgs
        self.commonModules.sharedHomeManager
      ]
      ++ modulesDarwin
      ++ inputModulesDarwin;
    };

  hostNames = builtins.attrNames (builtins.readDir ./../hosts);

  hostDefinitions = builtins.map (
    name:
    let
      path = ./../hosts + "/${name}";
    in
    {
      inherit name path;
      meta = import (path + "/meta.nix");
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
    nixosConfigurations = mkHostConfigurations "nixos" mkNixosConfiguration;
    darwinConfigurations = mkHostConfigurations "darwin" mkDarwinConfiguration;
  };
}
