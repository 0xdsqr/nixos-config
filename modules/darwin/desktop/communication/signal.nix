{
  flake.darwinModules.signal =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.communication.signal;
    in
    {
      options.dsqr.darwin.desktop.communication.signal = {
        enable = mkEnableOption "Signal desktop app";

        package = mkOption {
          type = str;
          default = "signal";
          description = "Homebrew cask to install for Signal.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
