{
  flake.homeModules.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrNames mapAttrsRecursive;
      inherit (lib.modules) mkDefault mkIf;
      inherit (lib.options) mkOption;
      inherit (lib.types) either enum;

      cfg = config.dsqr.home.herdr;
      tomlFormat = pkgs.formats.toml { };

      themes = {
        dsqr = {
          name = "terminal";
          custom = {
            accent = "#c7a0c0";
            panel_bg = "#161311";
            surface0 = "#2a241f";
            surface1 = "#4a3a2a";
            surface_dim = "#1f1b18";
            overlay0 = "#5a4633";
            overlay1 = "#6f6155";
            text = "#e7d9c8";
            subtext0 = "#6f6155";
            mauve = "#c7a0c0";
            green = "#b6c987";
            yellow = "#e7c784";
            red = "#df8f78";
            blue = "#98b7d8";
            teal = "#99cbbc";
            peach = "#d7b16d";
          };
        };

        moonstone = {
          name = "catppuccin";
          custom = {
            accent = "#7dcfff";
            panel_bg = "#171c2c";
            sidebar_bg = "#111622";
            active_row_bg = "#26344d";
            selection_bg = "#354866";
            surface0 = "#20293d";
            surface1 = "#2d3a54";
            surface_dim = "#141a28";
            overlay0 = "#465674";
            overlay1 = "#7888a6";
            text = "#dce6f5";
            subtext0 = "#a0aec5";
            mauve = "#b8a1e3";
            green = "#9acb9a";
            yellow = "#e7c98a";
            red = "#e58b95";
            blue = "#8aafe8";
            teal = "#83c8c2";
            peach = "#e5ac88";
          };
        };
      };

      selectedTheme =
        if builtins.isString cfg.theme then
          themes.${cfg.theme}
            or (throw "dsqr.home.herdr.theme: unknown preset '${cfg.theme}'; choose a preset or supply a theme table.")
        else
          cfg.theme;
    in
    {
      options.dsqr.home.herdr.theme = mkOption {
        type = either (enum (attrNames themes)) tomlFormat.type;
        default = "dsqr";
        example = {
          name = "tokyo-night";
          custom.accent = "#89b4fa";
        };
        description = ''
          Herdr theme preset (dsqr or moonstone), or a complete theme table
          using Herdr's theme.name and theme.custom format. A supplied table
          replaces the preset; it does not inherit the dsqr color overrides.
          See https://herdr.dev/docs/configuration/#theme.
        '';
      };

      config = mkIf cfg.enable { programs.herdr.settings.theme = mapAttrsRecursive (_: mkDefault) selectedTheme; };
    };
}
