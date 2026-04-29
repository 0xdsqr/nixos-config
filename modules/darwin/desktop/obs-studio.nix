{
  flake.darwinModules."obs-studio" =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.obs-studio;
    in
    {
      options.dsqr.darwin.desktop.obs-studio = {
        enable = mkEnableOption "OBS Studio desktop app";

        package = mkOption {
          type = str;
          default = "obs";
          description = "Homebrew cask to install for OBS Studio.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
