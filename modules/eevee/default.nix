inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import ./neovim.nix inputs )
    (import ./tmux.nix)
  ];
}
