inputs: {...}: {
  imports = [
    (import ./neovim.nix inputs)
    (import ./opencode.nix inputs)
    ./tmux.nix
    ./direnv.nix
    ./zsh.nix
    ./ghostty.nix
    ./starship.nix
    ./git.nix
  ];

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
      v = "code --wait";
      vim = "nvim";
      lg = "lazygit";
      ll = "ls -la";
      la = "ls -a";
    };
    extraConfig = ''
      $env.EDITOR = "code --wait"
      $env.VISUAL = "code --wait"
      $env.config.buffer_editor = "code --wait"
    '';
  };

  home.sessionVariables = {
    EDITOR = "code --wait";
    VISUAL = "code --wait";
  };
}
