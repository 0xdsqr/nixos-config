inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import ./neovim.nix inputs)
    (import ./tmux.nix)
    (import ./direnv.nix)
    (import ./zsh.nix)
    (import ./ghostty.nix)
    (import ./starship.nix)
    (import ./git.nix)
    (import ./opencode.nix)
  ];
}
