{
  flake.homeModules.ghostty =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.desktop.ghostty;
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
    in
    {
      options.dsqr.home.desktop.ghostty = {
        enable = mkEnableOption "Ghostty terminal" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
          description = "Ghostty package to install and configure.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = mkIf isLinux (singleton pkgs.ghostty.terminfo);

        programs.ghostty.enable = true;
        programs.ghostty.package = cfg.package;
        programs.ghostty.settings = {
          inherit (osConfig.theme.ghostty) background;
          inherit (osConfig.theme.ghostty) foreground;
          cursor-color = osConfig.theme.ghostty.cursorColor;
          cursor-text = osConfig.theme.ghostty.cursorText;
          inherit (osConfig.theme.ghostty) palette;
          selection-background = osConfig.theme.ghostty.selectionBackground;
          selection-foreground = osConfig.theme.ghostty.selectionForeground;
          unfocused-split-opacity = 0.82;
          unfocused-split-fill = osConfig.theme.ghostty.unfocusedSplitFill;
          split-divider-color = osConfig.theme.ghostty.splitDividerColor;

          font-family = osConfig.theme.font.mono.name;
          font-size = osConfig.theme.font.size.big;

          scrollback-limit = 100 * 1024 * 1024;
          mouse-hide-while-typing = true;
          mouse-scroll-multiplier = 0.95;
          confirm-close-surface = false;
          quit-after-last-window-closed = true;
          resize-overlay = "never";
          window-inherit-font-size = false;
          cursor-style = "block";
          cursor-style-blink = false;
          shell-integration-features = "no-cursor,ssh-env";
          window-padding-x = osConfig.theme.padding;
          window-padding-y = osConfig.theme.padding;

          keybind =
            mapAttrsToList (name: value: "ctrl+shift+${name}=${value}") {
              c = "copy_to_clipboard";
              v = "paste_from_clipboard";

              z = "jump_to_prompt:-2";
              x = "jump_to_prompt:2";

              h = "write_scrollback_file:paste";
              i = "inspector:toggle";

              page_down = "scroll_page_fractional:0.33";
              down = "scroll_page_lines:1";
              j = "scroll_page_lines:1";

              page_up = "scroll_page_fractional:-0.33";
              up = "scroll_page_lines:-1";
              k = "scroll_page_lines:-1";

              home = "scroll_to_top";
              end = "scroll_to_bottom";

              enter = "reset_font_size";
              plus = "increase_font_size:1";
              minus = "decrease_font_size:1";

              t = "new_window";
              q = "close_surface";

              "one" = "goto_tab:1";
              "two" = "goto_tab:2";
              "three" = "goto_tab:3";
              "four" = "goto_tab:4";
              "five" = "goto_tab:5";
              "six" = "goto_tab:6";
              "seven" = "goto_tab:7";
              "eight" = "goto_tab:8";
              "nine" = "goto_tab:9";
              "zero" = "goto_tab:10";
            }
            ++ mapAttrsToList (name: value: "ctrl+${name}=${value}") {
              "tab" = "next_tab";
              "shift+tab" = "previous_tab";
            };
        }
        // lib.optionalAttrs isDarwin {
          macos-option-as-alt = "left";
          macos-titlebar-style = "tabs";
          window-save-state = "never";
          window-decoration = true;
        };
      };
    };
}
