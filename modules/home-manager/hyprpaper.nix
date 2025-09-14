{
  config,
  pkgs,
  lib,
  ...
}: let
  selected_wallpaper_path = (import ../../lib/selected-wallpaper.nix config).wallpaper_path;
in {
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    "Pictures/Wallpapers" = {
      source = ../../config/themes/wallpapers;
      recursive = true;
    };
  };
  services.hyprpaper = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    settings = {
      preload = [
        selected_wallpaper_path
      ];
      wallpaper = [
        ",${selected_wallpaper_path}"
      ];
    };
  };
}