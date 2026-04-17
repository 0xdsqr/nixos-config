{ config, pkgs, ... }:
let
  inherit (config.dsqr.darwin) exo;
in
{
  system.defaults.dock = {
    autohide = true;
    showhidden = true;

    mouse-over-hilite-stack = true;

    show-recents = false;
    mru-spaces = false;

    tilesize = 48;
    magnification = false;

    enable-spring-load-actions-on-all-items = true;

    persistent-apps =
      if exo.enable then
        [ { app = "/Applications/Ghostty.app"; } ]
      else
        [
          { app = "${pkgs.vscode}/Applications/Visual Studio Code.app"; }
          { app = "/Applications/Ghostty.app"; }
          { app = "/Applications/Helium.app"; }
          { app = "/Applications/Tailscale.app"; }
          { app = "/Applications/Codex.app"; }
          { app = "/Applications/Spotify.app"; }
          { app = "/Applications/Discord.app"; }
        ];
  };

  system.defaults.CustomSystemPreferences."com.apple.dock" = {
    autohide-time-modifier = 0.0;
    autohide-delay = 0.0;
    expose-animation-duration = 0.0;
    springboard-show-duration = 0.0;
    springboard-hide-duration = 0.0;
    springboard-page-duration = 0.0;

    # Disable hot corners.
    wvous-tl-corner = 0;
    wvous-tr-corner = 0;
    wvous-bl-corner = 0;
    wvous-br-corner = 0;

    launchanim = 0;
  };
}
