{
  flake.homeModules.btop =
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

        xdg.configFile."btop/themes/dsqr.theme" = {
          text = config.dsqr.theme.btopTheme;
        };

        xdg.configFile."btop/btop.conf" = {
          text = /* ini */ ''
            color_theme = "dsqr"
            rounded_corners = ${if config.dsqr.theme.cornerRadius > 0 then "True" else "False"}
            vim_keys = True
          '';
        };
      };
    };
}
