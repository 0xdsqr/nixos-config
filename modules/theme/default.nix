_: {
  flake.commonModules.theme =
    {
      _class ? null,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs;
      inherit (lib.options) mkOption;
      inherit (lib.types)
        attrs
        bool
        int
        str
        ;

      isHomeManagerModule = _class == "homeManager";

      themeLib = import ./lib.nix { };
      themeCatalog = import ./catalog.nix {
        inherit pkgs;
        inherit themeLib;
      };

      selectedTheme =
        themeCatalog.${config.themeId}
          or (throw "Unknown theme '${config.themeId}'. Available themes: ${builtins.concatStringsSep ", " (builtins.attrNames themeCatalog)}");

      exportedThemeCatalog = mapAttrs (
        _: theme:
        builtins.removeAttrs theme [
          "themes"
          "active"
        ]
      ) themeCatalog;
    in
    {
      options.themeId = mkOption {
        type = str;
        default = "dsqr";
        description = "Active shared theme id.";
      };

      options.theme = {
        id = mkOption {
          type = str;
          readOnly = true;
          description = "Active shared theme id.";
        };

        name = mkOption {
          type = str;
          readOnly = true;
          description = "Active shared theme name.";
        };

        themes = mkOption {
          type = attrs;
          readOnly = true;
          description = "Resolved theme catalog keyed by theme name.";
        };

        active = mkOption {
          type = attrs;
          readOnly = true;
          description = "Resolved active theme payload.";
        };

        appearance = mkOption {
          type = str;
          default = "dark";
          description = "Active theme appearance variant.";
        };

        isDark = mkOption {
          type = bool;
          default = true;
          description = "Whether the active theme is dark.";
        };

        margin = mkOption {
          type = int;
          default = 8;
          description = "Shared outer layout margin.";
        };

        padding = mkOption {
          type = int;
          default = 8;
          description = "Shared inner UI padding.";
        };

        cornerRadius = mkOption {
          type = int;
          default = 0;
          description = "Shared corner radius token.";
        };

        wallpaper = mkOption {
          type = attrs;
          default = { };
          description = "Wallpaper metadata for Darwin and Linux consumers.";
        };

        colors = mkOption {
          type = attrs;
          default = { };
          description = "Raw theme color tokens.";
        };

        semantic = mkOption {
          type = attrs;
          default = { };
          description = "Derived semantic colors for shared consumers.";
        };

        btop = mkOption {
          type = attrs;
          default = { };
          description = "Derived btop theme payload.";
        };

        bat = mkOption {
          type = attrs;
          default = { };
          description = "Derived bat theme payload.";
        };

        difftastic = mkOption {
          type = attrs;
          default = { };
          description = "Derived difftastic theme payload.";
        };

        ghostty = mkOption {
          type = attrs;
          default = { };
          description = "Derived Ghostty theme payload.";
        };

        nushell = mkOption {
          type = attrs;
          default = { };
          description = "Derived Nushell prompt theme payload.";
        };

        font = mkOption {
          type = attrs;
          default = { };
          description = "Shared font tokens.";
        };
      };

      config = {
        theme = selectedTheme // {
          id = config.themeId;
          themes = exportedThemeCatalog;
          active = selectedTheme;
        };
      }
      // lib.optionalAttrs (!isHomeManagerModule) {
        fonts.packages = [
          config.theme.font.sans.package
          config.theme.font.mono.package
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-lgc-plus
          pkgs.noto-fonts-color-emoji
        ];
      };
    };
}
