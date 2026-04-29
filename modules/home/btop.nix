{
  flake.homeModules.btop =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.btop;
    in
    {
      options.dsqr.home.btop = {
        enable = mkEnableOption "btop system monitor" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.btop;
          description = "btop package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        xdg.configFile."btop/themes/${osConfig.theme.btop.colorTheme}.theme" = {
          text = osConfig.theme.btop.theme;
        };

        xdg.configFile."btop/btop.conf" = {
          text = /* ini */ ''
            color_theme = "${osConfig.theme.btop.colorTheme}"
            rounded_corners = False
            vim_keys = True
          '';
        };
      };
    };
}
