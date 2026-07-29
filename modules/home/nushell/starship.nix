{
  flake.homeModules.starship =
    { config, lib, ... }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.starship;
      jjCfg = config.dsqr.home.versionControl.jj;
      theme = config.dsqr.theme;
      promptAccent = theme.colors.magentaBright;
    in
    {
      options.dsqr.home.starship.enable = mkEnableOption "Starship prompt" // {
        default = true;
      };

      config = mkIf cfg.enable {
        programs.starship.enable = true;
        programs.starship.enableNushellIntegration = true;
        programs.starship.settings = {
          add_newline = true;
          command_timeout = 500;
          format = "$hostname$directory$git_branch$git_status$custom$nix_shell$cmd_duration$line_break$character";

          character = {
            error_symbol = "[✗](bold ${theme.colors.redBright})";
            success_symbol = "[❯](bold ${promptAccent})";
          };

          cmd_duration = {
            min_time = 2000;
            format = "took [$duration]($style) ";
            style = theme.colors.inactive;
          };

          directory = {
            truncation_length = 3;
            truncation_symbol = "…/";
            style = promptAccent;
            repo_root_style = "bold ${promptAccent}";
            repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
          };

          git_branch = {
            format = "[$branch]($style) ";
            style = "italic ${promptAccent}";
          };

          git_status = {
            format = "[$all_status]($style)";
            style = promptAccent;
            ahead = "⇡\${count} ";
            diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
            behind = "⇣\${count} ";
            conflicted = " ";
            up_to_date = " ";
            untracked = "? ";
            modified = " ";
            stashed = "";
            staged = "";
            renamed = "";
            deleted = "";
          };

          hostname = {
            ssh_only = true;
            format = "[$ssh_symbol$hostname]($style) ";
            style = "bold ${theme.colors.blueBright}";
          };

          line_break.disabled = false;

          nix_shell = {
            format = "[❄ $state]($style) ";
            style = "bold ${theme.colors.cyanBright}";
            impure_msg = "impure";
            pure_msg = "pure";
          };
        }
        // optionalAttrs jjCfg.enable {
          custom.jj = {
            command = "${getExe jjCfg.package} log --ignore-working-copy --no-graph --revisions @ --template 'change_id.shortest(8)'";
            format = "[jj $output]($style) ";
            style = "italic ${theme.colors.magenta}";
            when = "${getExe jjCfg.package} root";
          };
        };
      };
    };
}
