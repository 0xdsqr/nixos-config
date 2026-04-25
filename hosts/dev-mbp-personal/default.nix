{ self, ... }:
let
  inherit (self.lib)
    commonModules
    darwinModules
    homeModules
    nixLib
    ;
  inherit (nixLib.attrsets) attrValues removeAttrs;
  inherit (nixLib.lists) singleton;

  hostMeta = self.lib.mkHostMeta {
    class = "darwin";
    path = ./.;
    system = "aarch64-darwin";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      removeAttrs darwinModules [
        "desktop-stablecore"
        "monitoring-alloy-base"
        "monitoring-alloy-loki"
        "signal"
        "slack"
        "zoom"
      ]
    )
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        removeAttrs homeModules [
          "carapace"
          "cinny"
          "exo"
          "ollama"
          "signal"
        ]
      )
    )
    ++ [
      {
        networking = {
          hostName = "dev-mbp-personal";
          computerName = "dev-mbp-personal";
          localHostName = "dev-mbp-personal";
        };

        system.stateVersion = 5;
      }
    ];
in
{
  flake.hostDefinitions.dev-mbp-personal = hostMeta;

  flake.darwinConfigurations.dev-mbp-personal = self.lib.darwinSystem {
    inherit hostMeta modules;
    hostName = "dev-mbp-personal";
  };
}
