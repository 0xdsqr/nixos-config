{ inputs, ... }:
{
  flake.homeModules.web-browser =
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

      cfg = config.dsqr.home.desktop.browsers.helium;
    in
    {
      options.dsqr.home.desktop.browsers.helium = {
        enable = mkEnableOption "Helium browser" // {
          default = true;
        };

        package = mkOption {
          type = package;
          inherit (inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}) default;
          description = "Helium browser package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.BROWSER = "helium";
      };
    };
}
