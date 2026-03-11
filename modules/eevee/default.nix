inputs:
{
  ...
}:
{
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
      v = "nvim";
      vim = "nvim";
      lg = "lazygit";
      ll = "ls -la";
      la = "ls -a";
    };
    extraConfig = ''
      $env.config.buffer_editor = "nvim"
    '';
  };
}
