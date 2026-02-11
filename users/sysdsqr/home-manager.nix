{ isWSL, inputs, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
in
{
  imports = [
    (inputs.self.homeManagerModules.eevee inputs)
  ];

  eevee = import ../eevee-defaults.nix;

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
