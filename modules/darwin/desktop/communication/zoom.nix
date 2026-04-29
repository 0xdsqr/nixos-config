{
  flake.darwinModules.zoom =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.communication.zoom;
    in
    {
      options.dsqr.darwin.desktop.communication.zoom = {
        enable = mkEnableOption "Zoom desktop app";

        package = mkOption {
          type = str;
          default = "zoom";
          description = "Homebrew cask to install for Zoom.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
