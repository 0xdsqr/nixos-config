{
  flake.homeModules.discord =
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

      cfg = config.dsqr.home.desktop.communication.discord;
      inherit (pkgs.stdenv.hostPlatform) isLinux;
    in
    {
      options.dsqr.home.desktop.communication.discord = {
        enable = mkEnableOption "Discord desktop app";

        package = mkOption {
          type = package;
          default = pkgs.discord;
          description = "Discord package to install.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isLinux;
          message = "dsqr.home.desktop.communication.discord requires Linux.";
        };

        home.packages = optionals isLinux (singleton cfg.package);
      };
    };
}
