{
  flake.darwinModules.slack =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.communication.slack;
    in
    {
      options.dsqr.darwin.desktop.communication.slack = {
        enable = mkEnableOption "Slack desktop app";

        package = mkOption {
          type = str;
          default = "slack";
          description = "Homebrew cask to install for Slack.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
