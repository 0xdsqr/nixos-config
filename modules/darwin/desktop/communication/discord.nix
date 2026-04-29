{
  flake.darwinModules.discord =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.communication.discord;
    in
    {
      options.dsqr.darwin.desktop.communication.discord = {
        enable = mkEnableOption "Discord desktop app";

        package = mkOption {
          type = str;
          default = "vesktop";
          description = "Homebrew cask to install for Discord chat.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
