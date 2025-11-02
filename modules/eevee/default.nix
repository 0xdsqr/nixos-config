{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import ./neovim.nix)
    (import ./tmux.nix)
  ];
}
