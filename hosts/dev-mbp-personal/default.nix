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
    sshHost = "10.10.20.126";
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
        themeId = "im-in-love-with-emo-girl";

        networking = {
          hostName = "devbox-macbook-pro";
          computerName = "devbox-macbook-pro";
          localHostName = "devbox-macbook-pro";
        };

        system.stateVersion = 5;
      }
    ];
in
{
  flake.hostDefinitions.devbox-macbook-pro = hostMeta;
  flake.hostDefinitions.dev-mbp-personal = hostMeta;

  flake.darwinConfigurations.devbox-macbook-pro = self.lib.darwinSystem {
    inherit hostMeta modules;
    hostName = "devbox-macbook-pro";
  };

  flake.darwinConfigurations.dev-mbp-personal = self.lib.darwinSystem {
    inherit hostMeta modules;
    hostName = "dev-mbp-personal";
  };
}
