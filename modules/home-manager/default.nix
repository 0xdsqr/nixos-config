inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dsqrDevbox;

  packages = import ../packages.nix {
    inherit pkgs lib;
    exclude_packages = cfg.nixos.exclude_packages;
  };

  themes = import ../themes.nix;

  # Handle theme selection - either predefined or generated
  selectedTheme =
    if (cfg.theme == "generated_light" || cfg.theme == "generated_dark") then
      null
    else
      themes.${cfg.theme};

  # Generate color scheme from wallpaper for generated themes
  generatedColorScheme =
    if (cfg.theme == "generated_light" || cfg.theme == "generated_dark") then
      (inputs.nix-colors.lib.contrib { inherit pkgs; }).colorSchemeFromPicture {
        path = cfg.theme_overrides.wallpaper_path;
        variant = if cfg.theme == "generated_light" then "light" else "dark";
      }
    else
      null;
in
{
  imports = [
    (import ./hyprland.nix inputs)
    (import ./hyprlock.nix inputs)
    (import ./hyprpaper.nix)
    (import ./hypridle.nix)
    (import ./waybar.nix inputs)
    (import ./ghostty.nix)
    (import ./direnv.nix)
    (import ./starship.nix)
    (import ./zsh.nix)
    (import ./fonts.nix)
    (import ./jujutsu.nix)
  ];

  #home.file = {
  #  ".local/share/dsqr-nix/bin" = {
  #    source = ../../bin;
  #    recursive = true;
  #  };
  #};
  home.packages = packages.homePackages;

  colorScheme =
    if (cfg.theme == "generated_light" || cfg.theme == "generated_dark") then
      generatedColorScheme
    else
      inputs.nix-colors.colorSchemes.${selectedTheme.base16-theme};

  gtk = {
    enable = true;
    theme = {
      name = if cfg.theme == "generated_light" then "Adwaita" else "Adwaita:dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  # TODO: Add an actual nvim config
  programs.neovim = {
    enable = true;
    # Use nightly package from the input
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
