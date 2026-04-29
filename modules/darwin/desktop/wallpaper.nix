{
  flake.darwinModules."desktop-wallpaper" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.wallpaper;
      wallpaper = config.theme.wallpaper.darwin or null;
    in
    {
      options.dsqr.darwin.desktop.wallpaper.enable = mkEnableOption "desktop wallpaper activation";

      config = mkIf (cfg.enable && wallpaper != null) {
        system.activationScripts.setThemeWallpaper.text = mkAfter /* bash */ ''
          echo "setting desktop wallpaper from theme..."
          /usr/bin/osascript <<'EOF'
          tell application "Finder"
            set desktop picture to POSIX file "${toString wallpaper}"
          end tell
          EOF
        '';
      };
    };
}
