inputs:
{
  config,
  pkgs,
  ...
}:
{
  imports = [ ./hyprland/configuration.nix ];
  wayland.windowManager.hyprland = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
  services.hyprpolkitagent.enable = pkgs.stdenv.hostPlatform.isLinux;
}
