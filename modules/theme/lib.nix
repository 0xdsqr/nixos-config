_:
let
  mkNushellTheme = _: { primary = "#C8A2D0"; };

  mkBatTheme = theme: { themeName = if theme.isDark then "TwoDark" else "GitHub"; };

  mkBtopTheme =
    theme:
    let
      inherit (theme) colors;
    in
    {
      colorTheme = theme.name;
      theme = ''
        theme[main_bg]="${colors.bg0}"
        theme[main_fg]="${colors.fg1}"
        theme[title]="${colors.yellow}"
        theme[hi_fg]="${colors.yellow}"
        theme[selected_bg]="${colors.bg2}"
        theme[selected_fg]="${colors.fg0}"
        theme[inactive_fg]="${colors.fg2}"
        theme[graph_text]="${colors.yellowSoft}"
        theme[meter_bg]="${colors.bg1}"
        theme[proc_misc]="${colors.purple}"
        theme[cpu_box]="${colors.blue}"
        theme[mem_box]="${colors.green}"
        theme[net_box]="${colors.aqua}"
        theme[proc_box]="${colors.red}"
        theme[div_line]="${colors.border}"
        theme[temp_start]="${colors.green}"
        theme[temp_mid]="${colors.yellowSoft}"
        theme[temp_end]="${colors.red}"
        theme[cpu_start]="${colors.aqua}"
        theme[cpu_mid]="${colors.yellowSoft}"
        theme[cpu_end]="${colors.red}"
        theme[free_start]="${colors.aqua}"
        theme[free_mid]="${colors.green}"
        theme[free_end]="${colors.yellowSoft}"
        theme[cached_start]="${colors.blue}"
        theme[cached_mid]="${colors.purple}"
        theme[cached_end]="${colors.red}"
        theme[available_start]="${colors.aqua}"
        theme[available_mid]="${colors.green}"
        theme[available_end]="${colors.yellowSoft}"
        theme[used_start]="${colors.yellowSoft}"
        theme[used_mid]="${colors.red}"
        theme[used_end]="${colors.red}"
        theme[download_start]="${colors.blue}"
        theme[download_mid]="${colors.aqua}"
        theme[download_end]="${colors.green}"
        theme[upload_start]="${colors.purple}"
        theme[upload_mid]="${colors.yellowSoft}"
        theme[upload_end]="${colors.red}"
      '';
    };

  mkGhosttyTheme =
    theme:
    let
      inherit (theme) colors semantic;
    in
    {
      inherit (semantic) background;
      inherit (semantic) foreground;
      cursorColor = semantic.accent;
      cursorText = semantic.background;
      inherit (semantic) selectionBackground;
      inherit (semantic) selectionForeground;
      unfocusedSplitFill = semantic.surfaceLowest;
      splitDividerColor = semantic.border;
      palette = [
        "0=${colors.bg0}"
        "1=${colors.red}"
        "2=${colors.green}"
        "3=${colors.yellowSoft}"
        "4=${colors.blue}"
        "5=${colors.purple}"
        "6=${colors.aqua}"
        "7=${colors.fg1}"
        "8=${colors.fg2}"
        "9=${colors.redSoft}"
        "10=${colors.greenSoft}"
        "11=${colors.yellowBright}"
        "12=${colors.blueSoft}"
        "13=${colors.purpleSoft}"
        "14=${colors.aquaSoft}"
        "15=${colors.fg0}"
      ];
    };
in
rec {
  inherit
    mkBatTheme
    mkBtopTheme
    mkGhosttyTheme
    mkNushellTheme
    ;

  mkTheme =
    rawTheme:
    let
      baseTheme = rawTheme // {
        appearance = if rawTheme.isDark then "dark" else "light";
      };

      semantic =
        rawTheme.semantic or {
          background = rawTheme.colors.bg0;
          foreground = rawTheme.colors.fg1;
          foregroundStrong = rawTheme.colors.fg0;
          foregroundMuted = rawTheme.colors.fg2;
          accent = rawTheme.colors.yellow;
          inherit (rawTheme.colors) border;
          selectionBackground = rawTheme.colors.bg2;
          selectionForeground = rawTheme.colors.fg0;
          surface = rawTheme.colors.bg1;
          surfaceHighest = rawTheme.colors.bg2;
          surfaceLowest = rawTheme.colors.split;
          danger = rawTheme.colors.red;
          success = rawTheme.colors.green;
          info = rawTheme.colors.blue;
          warning = rawTheme.colors.yellowSoft;
        };
    in
    baseTheme
    // {
      inherit semantic;
      nushell = rawTheme.nushell or (mkNushellTheme baseTheme);
      bat = rawTheme.bat or (mkBatTheme baseTheme);
      difftastic = rawTheme.difftastic or { background = if baseTheme.isDark then "dark" else "light"; };
      ghostty = rawTheme.ghostty or (mkGhosttyTheme (baseTheme // { inherit semantic; }));
      btop = rawTheme.btop or (mkBtopTheme (baseTheme // { inherit semantic; }));
    };
}
