{
  flake.darwinModules.obsidian =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.obsidian;
    in
    {
      options.dsqr.darwin.desktop.obsidian = {
        enable = mkEnableOption "Obsidian desktop app";

        package = mkOption {
          type = str;
          default = "obsidian";
          description = "Homebrew cask to install for Obsidian.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
