{
  flake.homeModules.nushell-completion-menus =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption;

      nuCfg = config.dsqr.home.nu;
      cfg = nuCfg.completionMenus;
      colors = config.dsqr.theme.colors;
    in
    {
      options.dsqr.home.nu.completionMenus.enable = mkEnableOption "compact IDE and history menus for Nushell" // {
        default = true;
      };

      config.programs.nushell.extraConfig = mkIf (nuCfg.enable && nuCfg.integrations.enable && cfg.enable) (mkAfter /* nu */ ''
        do --env {
          let dsqr_menus = [
            {
              name: completion_menu
              only_buffer_difference: false
              marker: "› "
              type: {
                layout: ide
                min_completion_width: 0
                max_completion_width: 120
                max_completion_height: 20
                padding: 1
                border: false
                cursor_offset: 0
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 48
                max_description_height: 8
                description_offset: 1
                correct_cursor_pos: true
              }
              style: {
                text: ${builtins.toJSON colors.foreground}
                selected_text: {
                  fg: ${builtins.toJSON colors.foregroundBright}
                  bg: ${builtins.toJSON colors.selection}
                  attr: "b"
                }
                description_text: ${builtins.toJSON colors.inactive}
                match_text: {
                  fg: ${builtins.toJSON colors.magentaBright}
                  attr: "u"
                }
                selected_match_text: {
                  fg: ${builtins.toJSON colors.magentaBright}
                  bg: ${builtins.toJSON colors.selection}
                  attr: "bu"
                }
              }
            }
            {
              name: history_menu
              only_buffer_difference: true
              marker: "↺ "
              type: {
                layout: list
                page_size: 12
              }
              style: {
                text: ${builtins.toJSON colors.foreground}
                selected_text: {
                  fg: ${builtins.toJSON colors.foregroundBright}
                  bg: ${builtins.toJSON colors.selection}
                  attr: "b"
                }
              }
            }
          ]

          $env.config.menus = (
            $env.config.menus?
            | default []
            | where name not-in ($dsqr_menus | get name)
            | append $dsqr_menus
          )
        }
      '');
    };
}
