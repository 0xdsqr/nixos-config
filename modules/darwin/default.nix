_inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.eevee;
  casks = import ./casks.nix {
    inherit lib;
    inherit (cfg.darwin) exclude_casks;
  };
in
{
  imports = [
    ../common/nixpkgs.nix
  ];

  # CLI pkgs still from nixpkgs
  environment.systemPackages =
    (import ../packages.nix {
      inherit pkgs lib;
      inherit (cfg.nixos) exclude_packages;
    }).systemPackages;

  # Shell setup
  programs.zsh.enable = true;
  #programs.fish.enable = true;
  #programs.fish.shellInit = ''
  #  # Nix
  #  if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  #    source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  #  end
  #  # End Nix
  #'';
  environment.shells = with pkgs; [
    bashInteractive
    zsh
    # fish
  ];

  homebrew = {
    enable = true;
    inherit (casks) casks;
  };

  # Declarative Dock setup via nix-darwin defaults.
  system.defaults.dock = {
    persistent-apps = [
      "/Applications/Ghostty.app"
      "/Applications/Helium.app"
      "/Applications/Tailscale.app"
      "/Applications/Codex.app"
      "/Applications/Spotify.app"
      "/Applications/Discord.app"
    ];
    show-recents = true;
    static-only = false;
  };
}
