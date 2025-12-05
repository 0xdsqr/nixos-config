{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 200;
      format = "[$directory$git_branch$git_status$nix_shell]($style)$character";

      character = {
        error_symbol = "[✗](bold #C8A2D0)";
        success_symbol = "[❯](bold #C8A2D0)";
      };

      directory = {
        truncation_length = 2;
        truncation_symbol = "…/";
        style = "#C8A2D0";
        repo_root_style = "bold #C8A2D0";
        repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "italic #C8A2D0";
      };

      git_status = {
        format = "[$all_status]($style)";
        style = "#C8A2D0";
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

      nix_shell = {
        format = "[❄️ $state]($style) ";
        style = "bold #C8A2D0";
        impure_msg = "impure";
        pure_msg = "pure";
      };
    };
  };
}
