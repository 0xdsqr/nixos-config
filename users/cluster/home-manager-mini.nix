{ inputs, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (inputs.self.homeManagerModules.eevee-mini inputs)
  ];

  eevee = import ../eevee-defaults.nix;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
