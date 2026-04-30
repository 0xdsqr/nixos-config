{
  flake.homeModules.google-chrome =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.desktop.browsers.googleChrome;
    in
    {
      options.dsqr.home.desktop.browsers.googleChrome = {
        enable = mkEnableOption "Google Chrome browser";

        package = mkOption {
          type = package;
          default = pkgs.google-chrome;
          description = "Google Chrome package to install.";
        };
      };

      config = mkIf cfg.enable { home.packages = singleton cfg.package; };
    };
}
