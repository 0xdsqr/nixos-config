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
    ./tmux.nix
    ./direnv.nix
    ./zsh.nix
    ./ghostty.nix
    ./starship.nix
    ./git.nix
  ];
}
