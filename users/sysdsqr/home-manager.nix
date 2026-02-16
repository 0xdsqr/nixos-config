{ inputs, ... }:
{
  pkgs,
  ...
}:

{
  imports = [
    (inputs.self.homeManagerModules.eevee inputs)
  ];

  eevee = import ../eevee-defaults.nix;

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
