{
  flake.homeModules.cinny =
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

      cfg = config.dsqr.home.desktop.communication.cinny;
      inherit (pkgs.stdenv.hostPlatform) isLinux;
    in
    {
      options.dsqr.home.desktop.communication.cinny = {
        enable = mkEnableOption "Cinny desktop app";

        package = mkOption {
          type = package;
          default = pkgs.cinny-desktop;
          description = "Cinny package to install.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isLinux;
          message = "dsqr.home.desktop.communication.cinny requires Linux.";
        };

        home.packages = optionals isLinux (singleton cfg.package);
      };
    };
}
