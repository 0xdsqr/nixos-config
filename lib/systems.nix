{
  collectors,
  collectHostNix,
  collectNix,
  commonModules,
  darwinModules,
  homeModules,
  inputModulesDarwin,
  inputModulesNixos,
  inputs,
  keys,
  nixLib,
  nixosModules,
  profiles,
  self,
}:
let
  sharedSpecialArgs = {
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
  };

  mkHostMeta = host: host.meta // { inherit (host) path; };

  mkHostModuleArgs = hostMeta: {
    _module.args = {
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
        keys
        ;
      meta = hostMeta;
      inherit hostMeta;
      ctx = {
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
          keys
          hostMeta
          ;
      };
    };
  };

  mkHostConfigurations =
    class: builder: hostDefinitions:
    builtins.listToAttrs (
      builtins.map (host: {
        inherit (host) name;
        value = builder host.name host.meta.system host;
      }) (builtins.filter (host: host.meta.class == class) hostDefinitions)
    );

  mkNixosConfiguration =
    name: system: host:
    let
      hostMeta = mkHostMeta host;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = sharedSpecialArgs // {
        inherit (inputs) agenix exo nix-openclaw;
        hostName = name;
        inherit hostMeta;
      };

      modules = [
        { nixpkgs.hostPlatform = nixLib.mkDefault system; }
        host.module
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.default
        (mkHostModuleArgs hostMeta)
      ]
      ++ inputModulesNixos;
    };

  mkDarwinConfiguration =
    name: system: host:
    let
      hostMeta = mkHostMeta host;
    in
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = sharedSpecialArgs // {
        inherit (inputs) agenix exo nix-openclaw;
        hostName = name;
        inherit hostMeta;
      };

      modules = [
        { nixpkgs.hostPlatform = nixLib.mkDefault system; }
        host.module
        inputs.agenix.darwinModules.default
        inputs.home-manager.darwinModules.default
        (mkHostModuleArgs hostMeta)
      ]
      ++ inputModulesDarwin;
    };
in
{
  inherit mkDarwinConfiguration mkHostConfigurations mkNixosConfiguration;
}
