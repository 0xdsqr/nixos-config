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
        "bat"
        "clipboard"
        "window-manager"
        "desktop-personal"
        "desktop-stablecore"
        "discord"
        "google-chrome"
        "hammerspoon"
        "helium"
        "monitoring-alloy-base"
        "monitoring-alloy-loki"
        "obs-studio"
        "packages"
        "signal"
        "slack"
        "spotify"
        "zoom"
      ]
    )
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        removeAttrs homeModules [
          "aws"
          "bat"
          "btop"
          "carapace"
          "cinny"
          "claude-code"
          "codex"
          "window-manager"
          "difftastic"
          "direnv"
          "discord"
          "exo"
          "hammerspoon"
          "hushlogin"
          "ollama"
          "opencode"
          "packages-containers"
          "packages-databases"
          "packages-debugging"
          "packages-kubernetes"
          "packages-media"
          "packages-node"
          "packages-shell-utils"
          "packages-signing"
          "pi"
          "signal"
          "theme"
          "thunderbird"
          "web-browser"
        ]
      )
    )
    ++ [
      {
        networking = {
          hostName = "srv-mini-master";
          computerName = "srv-mini-master";
          localHostName = "srv-mini-master";
        };

        system.activationScripts.miniClusterPower.text = /* bash */ ''
          /usr/bin/pmset -a sleep 0 \
            displaysleep 0 \
            disksleep 0 \
            standby 0 \
            autopoweroff 0 \
            womp 1 \
            tcpkeepalive 1 \
            autorestart 1 \
            powernap 1
        '';

        system.stateVersion = 5;
      }
    ];
in
{
  flake.hostDefinitions.srv-mini-master = hostMeta;

  flake.darwinConfigurations.srv-mini-master = self.lib.darwinSystem {
    inherit hostMeta modules;
    hostName = "srv-mini-master";
  };
}
