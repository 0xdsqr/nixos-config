{
  flake.darwinModules.codexbar =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.codexbar;
    in
    {
      options.dsqr.darwin.desktop.codexbar = {
        enable = mkEnableOption "CodexBar desktop app";

        package = mkOption {
          type = str;
          default = "codexbar";
          description = "Homebrew cask to install for CodexBar.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
