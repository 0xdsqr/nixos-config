{
  flake.darwinModules.grok-bot =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.grokBot;
    in
    {
      options.dsqr.darwin.desktop.grokBot = {
        enable = mkEnableOption "Grok Bot desktop app";

        package = mkOption {
          type = str;
          default = "grok-bot";
          description = "Homebrew cask to install for the Grok Bot desktop app.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
