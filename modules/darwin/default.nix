inputs:
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
    exclude_casks = cfg.darwin.exclude_casks;
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
      exclude_packages = cfg.nixos.exclude_packages;
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
}
