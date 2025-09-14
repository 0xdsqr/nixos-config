{ isWSL, inputs, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  shellAliases = {
    ".." = "cd ..";
  }
  // (
    if isLinux then
      {
        # Linux-specific aliases
      }
    else
      {
        # macOS-specific aliases
      }
  );
in
{
  imports = [
    # Import dsqr-nix home-manager module
    (inputs.self.homeManagerModules.dsqr-nix inputs)
  ];

  # Configure dsqr-nix module
  dsqrDevbox = {
    theme = "tokyo-night";
  };

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
