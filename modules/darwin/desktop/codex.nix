{
  flake.darwinModules.codex =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.codex;
    in
    {
      options.dsqr.darwin.desktop.codex = {
        enable = mkEnableOption "Codex desktop app";

        package = mkOption {
          type = str;
          default = "codex-app";
          description = "Homebrew cask to install for the Codex desktop app.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
