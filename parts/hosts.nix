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
      specialArgs = inputs // {
        inherit dtil inputs keys;
        hostName = name;
      };

      modules = [
        module
        (mkRemoteBuilderModule name)
      ]
      ++ modulesCommon
      ++ modulesNixos
      ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    name: system: module:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = inputs // {
        inherit dtil inputs keys;
        hostName = name;
      };

      modules = [
        module
        (mkRemoteBuilderModule name)
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

  builderDefinitions =
    let
      mkNixosBuilder = name: {
        inherit name;
        value =
          self.hostDefinitions.${name}
          // self.nixosConfigurations.${name}.config.dsqr.nixos.builder
          // {
            inherit name;
            enable = self.nixosConfigurations.${name}.config.dsqr.nixos.builder.enable;
          };
      };

      mkDarwinBuilder = name: {
        inherit name;
        value =
          self.hostDefinitions.${name}
          // self.darwinConfigurations.${name}.config.dsqr.darwin.builder
          // {
            inherit name;
            enable = self.darwinConfigurations.${name}.config.dsqr.darwin.builder.enable;
          };
      };
    in
    builtins.listToAttrs (
      builtins.map mkNixosBuilder (builtins.attrNames self.nixosConfigurations)
      ++ builtins.map mkDarwinBuilder (builtins.attrNames self.darwinConfigurations)
    );

  mkRemoteBuilderModule =
    currentName:
    { lib, ... }:
    let
      buildMachines =
        builtins.removeAttrs builderDefinitions [ currentName ]
        |> builtins.attrValues
        |> builtins.filter (builder: builder.enable && builder.sshHost != null)
        |> builtins.map (builder: {
          hostName = builder.name;
          sshUser = builder.sshUser;
          protocol = "ssh-ng";
          maxJobs = builder.maxJobs;
          speedFactor = builder.speedFactor;
          system = builder.system;
          supportedFeatures = builder.supportedFeatures;
          systems = builder.systems;
        });
    in
    lib.mkIf (buildMachines != [ ]) {
      nix.distributedBuilds = true;
      nix.buildMachines = buildMachines;
      nix.settings.builders-use-substitutes = true;
    };
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
    inherit builderDefinitions;
  };
}
