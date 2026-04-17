_: {
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      edit_mode = "vi";
      history.file_format = "sqlite";
      completions = {
        algorithm = "fuzzy";
        quick = true;
        partial = true;
      };
    };
    shellAliases = {
      v = "nvim";
      vim = "nvim";
      lg = "lazygit";
      ll = "ls -la";
      la = "ls -a";
    };
    extraConfig = ''
      $env.EDITOR = "nvim"
      $env.VISUAL = "nvim"
      $env.config.buffer_editor = "nvim"
    '';
  };
}
