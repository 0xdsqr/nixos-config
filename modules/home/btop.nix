{
  flake.homeModules.btop =
    { osConfig, pkgs, ... }:
    {
      home.packages = [ pkgs.btop ];

      xdg.configFile."btop/themes/${osConfig.theme.btop.colorTheme}.theme".text = osConfig.theme.btop.theme;

      xdg.configFile."btop/btop.conf".text = ''
        color_theme = "${osConfig.theme.btop.colorTheme}"
        rounded_corners = False
        vim_keys = True
      '';
    };
}
