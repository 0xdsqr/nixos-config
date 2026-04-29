{
  flake.homeModules.signal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) optionals singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.desktop.communication.signal;
      inherit (pkgs.stdenv.hostPlatform) isLinux;
    in
    {
      options.dsqr.home.desktop.communication.signal = {
        enable = mkEnableOption "Signal desktop app";

        package = mkOption {
          type = package;
          default = pkgs.signal-desktop;
          description = "Signal Desktop package to install.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isLinux;
          message = "dsqr.home.desktop.communication.signal requires Linux.";
        };

        home.packages = optionals isLinux (singleton cfg.package);
      };
    };
}
