{
  flake.darwinModules =
    let
      sharedCasks = [ "docker-desktop" ];

      sharedDesktop = {
        homebrew.casks = sharedCasks;

        # Keep this old Dock app list nearby while we settle on the new baseline:
        # system.defaults.dock.persistent-apps = builtins.map (app: { inherit app; }) [
        #   "/Applications/Ghostty.app"
        #   "/Applications/Helium.app"
        #   "/Applications/Tailscale.app"
        #   "/Applications/Codex.app"
        #   "/Applications/Spotify.app"
        #   "/Applications/Discord.app"
        # ];

        system.defaults = {
          dock = {
            autohide = true;
            showhidden = true;
            mouse-over-hilite-stack = true;
            show-recents = false;
            mru-spaces = false;
            tilesize = 48;
            magnification = false;
            enable-spring-load-actions-on-all-items = true;
          };

          CustomSystemPreferences."com.apple.dock" = {
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

          menuExtraClock = {
            Show24Hour = true;
            ShowSeconds = true;
          };

          controlcenter = {
            BatteryShowPercentage = true;
            Bluetooth = true;
          };

          screencapture.location = "~/Downloads/Screenshots";

          NSGlobalDomain.AppleICUForce24HourTime = true;

          trackpad = {
            Clicking = false;
            Dragging = false;
          };
        };
      };
    in
    {
      "desktop-personal" = _: sharedDesktop;

      "desktop-stablecore" = _: sharedDesktop;
    };
}
