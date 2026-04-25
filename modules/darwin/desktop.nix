{
  flake.darwinModules =
    let
      sharedCasks = [ "docker-desktop" ];

      sharedDock = {
        system.defaults.dock = {
          autohide = true;
          showhidden = true;
          mouse-over-hilite-stack = true;
          show-recents = false;
          mru-spaces = false;
          tilesize = 48;
          magnification = false;
          enable-spring-load-actions-on-all-items = true;
        };

        system.defaults.CustomSystemPreferences."com.apple.dock" = {
          autohide-time-modifier = 0.0;
          autohide-delay = 0.0;
          expose-animation-duration = 0.0;
          springboard-show-duration = 0.0;
          springboard-hide-duration = 0.0;
          springboard-page-duration = 0.0;
          wvous-tl-corner = 0;
          wvous-tr-corner = 0;
          wvous-bl-corner = 0;
          wvous-br-corner = 0;
          launchanim = 0;
        };
      };

      sharedDesktopDefaults = {
        # Keep this old Dock app list nearby while we settle on the new baseline:
        # system.defaults.dock.persistent-apps = builtins.map (app: { inherit app; }) [
        #   "/Applications/Ghostty.app"
        #   "/Applications/Helium.app"
        #   "/Applications/Tailscale.app"
        #   "/Applications/Codex.app"
        #   "/Applications/Spotify.app"
        #   "/Applications/Discord.app"
        # ];

        system.defaults.menuExtraClock = {
          Show24Hour = true;
          ShowSeconds = true;
        };

        system.defaults.controlcenter = {
          BatteryShowPercentage = true;
          Bluetooth = true;
        };

        system.defaults.screencapture.location = "~/Downloads/Screenshots";

        system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;

        system.defaults.trackpad = {
          Clicking = false;
          Dragging = false;
        };
      };

      sharedDesktop = {
        homebrew.casks = sharedCasks;
      }
      // sharedDesktopDefaults
      // sharedDock;
    in
    {
      "desktop-personal" = _: sharedDesktop;

      "desktop-stablecore" = _: sharedDesktop;
    };
}
