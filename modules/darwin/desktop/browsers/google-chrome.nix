{
  flake.darwinModules.google-chrome =
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
      cfg = config.dsqr.darwin.desktop.browsers.googleChrome;
    in
    {
      options.dsqr.darwin.desktop.browsers.googleChrome = {
        enable = mkEnableOption "Google Chrome browser";

        package = mkOption {
          type = package;
          default = pkgs.google-chrome;
          description = "Nix package to install for Google Chrome.";
        };
      };

      config = mkIf cfg.enable {
        allowedUnfreePackageNames = singleton "google-chrome";
        environment.systemPackages = singleton cfg.package;
      };
    };
}
