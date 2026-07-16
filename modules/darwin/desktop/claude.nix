{
  flake.darwinModules.claude =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.claude;
    in
    {
      options.dsqr.darwin.desktop.claude = {
        enable = mkEnableOption "Claude desktop app with Claude Code";

        package = mkOption {
          type = str;
          default = "claude";
          description = "Homebrew cask to install for the Claude desktop app.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
