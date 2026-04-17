{ pkgs, ... }:
let
  inherit (pkgs) bashInteractive zsh;
in
{
  programs.zsh.enable = true;

  environment.shells = [
    bashInteractive
    zsh
  ];
}
