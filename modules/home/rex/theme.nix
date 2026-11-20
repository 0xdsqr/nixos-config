{
  flake.homeModules.rex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) listToAttrs nameValuePair;
      inherit (lib.lists) elemAt genList;
      inherit (lib.modules) mkDefault mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) substring;
      inherit (lib.trivial) fromHexString mod;
      inherit (lib.types) str;

      cfg = config.dsqr.home.rex;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      theme = config.dsqr.theme;
      inherit (theme) colors;

      # Rex stores each color as sRGB components between 0 and 1.
      rgb = red: green: blue: {
        red = red / 255.0;
        green = green / 255.0;
        blue = blue / 255.0;
        alpha = 1;
        colorSpace = "srgb";
      };

      channel = hex: offset: fromHexString (substring offset 2 hex);
      color = hex: rgb (channel hex 1) (channel hex 3) (channel hex 5);

      # xterm's standard colors 16-255: a 6x6x6 cube, then 24 grays.
      cubeLevel = index: elemAt [ 0 95 135 175 215 255 ] index;
      cubeColor = index: rgb (cubeLevel (index / 36)) (cubeLevel (mod (index / 6) 6)) (cubeLevel (mod index 6));
      grayColor =
        index:
        let
          level = 8 + 10 * index;
        in
        rgb level level level;
      extendedPalette = listToAttrs (
        genList (index: nameValuePair (toString (16 + index)) (cubeColor index)) 216
        ++ genList (index: nameValuePair (toString (232 + index)) (grayColor index)) 24
      );

      themeId = "custom-D5D5C0DE-0000-4000-8000-000000000001";

      customTheme = {
        id = themeId;
        inherit (cfg.theme) name;
        appearance = if theme.isDark then "dark" else "light";
        createdAt = 800000000;
        source.ghosttyFile.fileName = "nix-dsqr-theme";
        palette = {
          background = color colors.background;
          foreground = color colors.foreground;
          cursor = color colors.accent;
          cursorText = color colors.background;
          selectionBackground = color colors.selection;
          selectionForeground = color colors.foregroundBright;
          ansi = map color [
            colors.background
            colors.red
            colors.green
            colors.yellow
            colors.blue
            colors.magenta
            colors.cyan
            colors.foreground
            colors.inactive
            colors.redBright
            colors.greenBright
            colors.yellowBright
            colors.blueBright
            colors.magentaBright
            colors.cyanBright
            colors.foregroundBright
          ];
          paletteBase = extendedPalette;
          paletteOverrides = { };
          paletteGenerate = false;
          paletteHarmonious = false;
        };
      };
    in
    {
      options.dsqr.home.rex.theme = {
        enable = mkEnableOption "the shared dsqr theme, font, and padding in Rex for Mac" // {
          default = true;
        };

        name = mkOption {
          type = str;
          default = "dsqr";
          description = "Name of the generated theme in Rex's theme list.";
        };
      };

      config = mkIf (cfg.enable && cfg.theme.enable && isDarwin) {
        dsqr.home.rex = {
          settings = {
            "Workspace.appearance" = mkDefault (if theme.isDark then "dark" else "light");
            "Workspace.${if theme.isDark then "dark" else "light"}ThemeID" = mkDefault themeId;
            "Workspace.terminalFontName" = mkDefault theme.font.mono.name;
            "Workspace.terminalFontPointSize" = mkDefault theme.font.size.terminal;
            "Workspace.terminalPaddingX" = mkDefault theme.padding;
            "Workspace.terminalPaddingY" = mkDefault theme.padding;
            "Workspace.sidebarTextPointSize" = mkDefault theme.font.size.normal;
          };

          # Rex keeps every custom theme in this one key, so the generated theme
          # replaces any imported through the app.
          dataSettings."Workspace.customThemes" = mkDefault (
            pkgs.writeText "rex-custom-themes.json" (builtins.toJSON [ customTheme ])
          );
        };
      };
    };
}
