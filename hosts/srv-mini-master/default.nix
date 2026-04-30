{ self, ... }:
let
  inherit (self.lib)
    commonModules
    darwinModules
    homeModules
    nixLib
    ;
  inherit (nixLib.attrsets) attrValues;
  inherit (nixLib.lists) singleton;

  hostName = "srv-mini-master";

  modules =
    attrValues commonModules ++ attrValues darwinModules ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "darwin";
    path = ./.;
    system = "aarch64-darwin";
  };

  flake.darwinConfigurations.${hostName} = self.lib.darwinSystem {
    inherit hostName;

    modules = singleton (
      { ... }:
      {
        imports = modules;

        dsqr.darwin.profiles.miniServer.enable = true;

        system.stateVersion = 5;
      }
    );
  };
}
