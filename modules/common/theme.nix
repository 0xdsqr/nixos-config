{ self, ... }: {
  flake.commonModules.theme =
    { lib, pkgs, ... }:
    let
      inherit (lib.modules) mkDefault;
      inherit (lib.options) mkOption;
      inherit (lib.types) attrs;

      colors = {
        background = "#1f1b18";
        backgroundDark = "#161311";
        backgroundSoft = "#2a241f";
        selection = "#4a3a2a";
        inactive = "#6f6155";
        foreground = "#e7d9c8";
        foregroundBright = "#f7efe5";
        accent = "#f0c674";
        divider = "#5a4633";

        red = "#c97b63";
        redBright = "#df8f78";
        green = "#9aad6d";
        greenBright = "#b6c987";
        yellow = "#d7b16d";
        yellowBright = "#e7c784";
        blue = "#7ea1c5";
        blueBright = "#98b7d8";
        magenta = "#b48ead";
        magentaBright = "#c7a0c0";
        cyan = "#7eb5a6";
        cyanBright = "#99cbbc";
      };
    in
    {
      options.dsqr.theme = mkOption {
        type = attrs;
        default = { };
        description = "Shared visual style tokens for desktop and terminal tools.";
      };

      config.dsqr.theme = mkDefault {
        isDark = true;
        inherit colors;

        cornerRadius = 4;
        borderWidth = 2;
        margin = 0;
        padding = 8;

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
            terminal = 20;
            big = 20;
          };
        };

        ghosttyPalette = [
          "0=${colors.background}"
          "1=${colors.red}"
          "2=${colors.green}"
          "3=${colors.yellow}"
          "4=${colors.blue}"
          "5=${colors.magenta}"
          "6=${colors.cyan}"
          "7=${colors.foreground}"
          "8=${colors.inactive}"
          "9=${colors.redBright}"
          "10=${colors.greenBright}"
          "11=${colors.yellowBright}"
          "12=${colors.blueBright}"
          "13=${colors.magentaBright}"
          "14=${colors.cyanBright}"
          "15=${colors.foregroundBright}"
        ];

        btopTheme = /* ini */ ''
          theme[main_bg]="${colors.background}"
          theme[main_fg]="${colors.foreground}"
          theme[title]="${colors.accent}"
          theme[hi_fg]="${colors.accent}"
          theme[selected_bg]="${colors.selection}"
          theme[selected_fg]="${colors.foregroundBright}"
          theme[inactive_fg]="${colors.inactive}"
          theme[graph_text]="${colors.yellow}"
          theme[meter_bg]="${colors.backgroundSoft}"
          theme[proc_misc]="${colors.magenta}"
          theme[cpu_box]="${colors.blue}"
          theme[mem_box]="${colors.green}"
          theme[net_box]="${colors.cyan}"
          theme[proc_box]="${colors.red}"
          theme[div_line]="${colors.divider}"
          theme[temp_start]="${colors.green}"
          theme[temp_mid]="${colors.yellow}"
          theme[temp_end]="${colors.red}"
          theme[cpu_start]="${colors.cyan}"
          theme[cpu_mid]="${colors.yellow}"
          theme[cpu_end]="${colors.red}"
          theme[free_start]="${colors.cyan}"
          theme[free_mid]="${colors.green}"
          theme[free_end]="${colors.yellow}"
          theme[cached_start]="${colors.blue}"
          theme[cached_mid]="${colors.magenta}"
          theme[cached_end]="${colors.red}"
          theme[available_start]="${colors.cyan}"
          theme[available_mid]="${colors.green}"
          theme[available_end]="${colors.yellow}"
          theme[used_start]="${colors.yellow}"
          theme[used_mid]="${colors.red}"
          theme[used_end]="${colors.red}"
          theme[download_start]="${colors.blue}"
          theme[download_mid]="${colors.cyan}"
          theme[download_end]="${colors.green}"
          theme[upload_start]="${colors.magenta}"
          theme[upload_mid]="${colors.yellow}"
          theme[upload_end]="${colors.red}"
        '';

        batTheme = /* xml */ ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>name</key>
            <string>dsqr</string>
            <key>settings</key>
            <array>
              <dict>
                <key>settings</key>
                <dict>
                  <key>background</key>
                  <string>${colors.background}</string>
                  <key>foreground</key>
                  <string>${colors.foreground}</string>
                  <key>caret</key>
                  <string>${colors.accent}</string>
                  <key>selection</key>
                  <string>${colors.selection}</string>
                  <key>invisibles</key>
                  <string>${colors.inactive}</string>
                  <key>lineHighlight</key>
                  <string>${colors.backgroundSoft}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Comment</string>
                <key>scope</key>
                <string>comment</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.inactive}</string>
                  <key>fontStyle</key>
                  <string>italic</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>String</string>
                <key>scope</key>
                <string>string</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.green}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Constant</string>
                <key>scope</key>
                <string>constant, support.constant</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.cyan}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Keyword</string>
                <key>scope</key>
                <string>keyword, storage</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.red}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Function</string>
                <key>scope</key>
                <string>entity.name.function, support.function</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.blue}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Type</string>
                <key>scope</key>
                <string>entity.name.type, support.type, storage.type</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.yellow}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Variable</string>
                <key>scope</key>
                <string>variable, variable.parameter</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>${colors.magenta}</string>
                </dict>
              </dict>
            </array>
          </dict>
          </plist>
        '';
      };
    };

  flake.homeModules.theme = self.commonModules.theme;
}
