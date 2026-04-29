{
  flake.darwinModules.hammerspoon =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.hammerspoon;
    in
    {
      options.dsqr.darwin.desktop.hammerspoon = {
        enable = mkEnableOption "Hammerspoon desktop automation";

        package = mkOption {
          type = str;
          default = "hammerspoon";
          description = "Homebrew cask to install for Hammerspoon.";
        };

        configFile = mkOption {
          type = str;
          default = "~/.config/hammerspoon/init.lua";
          description = "Path Hammerspoon should load as its main config file.";
        };
      };

      config = mkIf cfg.enable {
        homebrew.casks = singleton cfg.package;

        system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon".MJConfigFile = cfg.configFile;
      };
    };
}
