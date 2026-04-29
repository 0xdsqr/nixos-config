{
  flake.darwinModules.spotify =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.spotify;
    in
    {
      options.dsqr.darwin.desktop.spotify = {
        enable = mkEnableOption "Spotify desktop app" // {
          default = true;
        };

        package = mkOption {
          type = str;
          default = "spotify";
          description = "Homebrew cask to install for Spotify.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
