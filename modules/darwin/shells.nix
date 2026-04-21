{ config, pkgs, ... }:
let
  inherit (pkgs) bashInteractive zsh;
in
{
  programs.zsh.enable = true;

  environment.shells = [
    bashInteractive
    zsh
  ];

  users.users.${config.system.primaryUser}.shell = zsh;
}
