_: {
  flake.commonModules.theme =
    {
      _class ? null,
      lib,
      pkgs,
      ...
    }:
    let
      isHomeManagerModule = _class == "homeManager";

      themeConfig = {
        theme = {
          isDark = true;
          margin = 8;
          padding = 8;

          btop = {
            colorTheme = "dsqr";
            theme = ''
              theme[main_bg]="#1f1b18"
              theme[main_fg]="#e7d9c8"
              theme[title]="#f0c674"
              theme[hi_fg]="#f0c674"
              theme[selected_bg]="#4a3a2a"
              theme[selected_fg]="#f7efe5"
              theme[inactive_fg]="#6f6155"
              theme[graph_text]="#d7b16d"
              theme[meter_bg]="#2a241f"
              theme[proc_misc]="#b48ead"
              theme[cpu_box]="#7ea1c5"
              theme[mem_box]="#9aad6d"
              theme[net_box]="#7eb5a6"
              theme[proc_box]="#c97b63"
              theme[div_line]="#5a4633"
              theme[temp_start]="#9aad6d"
              theme[temp_mid]="#d7b16d"
              theme[temp_end]="#c97b63"
              theme[cpu_start]="#7eb5a6"
              theme[cpu_mid]="#d7b16d"
              theme[cpu_end]="#c97b63"
              theme[free_start]="#7eb5a6"
              theme[free_mid]="#9aad6d"
              theme[free_end]="#d7b16d"
              theme[cached_start]="#7ea1c5"
              theme[cached_mid]="#b48ead"
              theme[cached_end]="#c97b63"
              theme[available_start]="#7eb5a6"
              theme[available_mid]="#9aad6d"
              theme[available_end]="#d7b16d"
              theme[used_start]="#d7b16d"
              theme[used_mid]="#c97b63"
              theme[used_end]="#c97b63"
              theme[download_start]="#7ea1c5"
              theme[download_mid]="#7eb5a6"
              theme[download_end]="#9aad6d"
              theme[upload_start]="#b48ead"
              theme[upload_mid]="#d7b16d"
              theme[upload_end]="#c97b63"
            '';
          };

          ghostty = {
            background = "#1f1b18";
            foreground = "#e7d9c8";
            cursorColor = "#f0c674";
            cursorText = "#1f1b18";
            selectionBackground = "#4a3a2a";
            selectionForeground = "#f7efe5";
            unfocusedSplitFill = "#161311";
            splitDividerColor = "#5a4633";
            palette = [
              "0=#1f1b18"
              "1=#c97b63"
              "2=#9aad6d"
              "3=#d7b16d"
              "4=#7ea1c5"
              "5=#b48ead"
              "6=#7eb5a6"
              "7=#e7d9c8"
              "8=#6f6155"
              "9=#df8f78"
              "10=#b6c987"
              "11=#e7c784"
              "12=#98b7d8"
              "13=#c7a0c0"
              "14=#99cbbc"
              "15=#f7efe5"
            ];
          };

          font = {
            sans = {
              name = "Lexend";
              package = pkgs.lexend;
            };

            mono = {
              name = "JetBrainsMono Nerd Font";
              package = pkgs.nerd-fonts.jetbrains-mono;
            };

            size = {
              normal = 16;
              terminal = 22;
              large = 18;
              big = 20;
            };
          };
        };
      };
    in
    {
      options.theme = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = lib.mkMerge [
        themeConfig
        (lib.optionalAttrs (!isHomeManagerModule) {
          fonts.packages = [
            pkgs.noto-fonts
            pkgs.noto-fonts-cjk-sans
            pkgs.noto-fonts-lgc-plus
            pkgs.noto-fonts-color-emoji
            pkgs.lexend
            pkgs.nerd-fonts.jetbrains-mono
          ];
        })
      ];
    };
}
