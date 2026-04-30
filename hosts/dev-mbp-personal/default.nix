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

  hostMeta = self.lib.mkHostMeta {
    class = "darwin";
    path = ./.;
    sshHost = "10.10.20.126";
    system = "aarch64-darwin";
  };

  modules =
    attrValues commonModules
    ++ attrValues darwinModules
    ++ singleton (self.lib.mkHomeManagerSharedModule homeModules)
    ++ singleton {
      dsqr = {
        theme.id = "im-in-love-with-emo-girl";

        darwin = {
          determinate.enable = true;
          hostname.smb.enable = true;

          desktop = {
            dock.enable = true;
            system.enable = true;
            wallpaper.enable = true;
            windowManager.enable = true;
            maccy.enable = true;
            codex.enable = true;
            hammerspoon.enable = true;
            obs-studio.enable = true;
            communication.discord.enable = true;
          };
        };

      };

      allowedUnfreePackageNames = [ "google-chrome" ];

      home-manager.users.dsqr.dsqr.home.desktop = {
        browsers.googleChrome.enable = true;
        codexbar.enable = true;
        hammerspoon.enable = true;
        windowManager.enable = true;
      };

      networking = {
        hostName = "devbox-macbook-pro";
        computerName = "devbox-macbook-pro";
        localHostName = "devbox-macbook-pro";
      };

      system.stateVersion = 5;
    };
in
{
  flake.hostDefinitions.dev-mbp-personal = hostMeta;

  flake.darwinConfigurations.dev-mbp-personal = self.lib.darwinSystem {
    inherit hostMeta modules;
    hostName = "dev-mbp-personal";
  };
}
