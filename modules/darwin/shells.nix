{ config, pkgs, ... }:
let
  inherit (pkgs) bashInteractive nushell zsh;
in
{
  programs.zsh.enable = true;

  environment.shells = [
    bashInteractive
    nushell
    zsh
  ];

  users.users.${config.system.primaryUser}.shell = nushell;
}
