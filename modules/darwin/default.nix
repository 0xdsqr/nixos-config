inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dsqrDevbox;
  casks = import ./casks.nix {
    inherit lib;
    exclude_casks = cfg.darwin.exclude_casks;
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # CLI pkgs still from nixpkgs
  environment.systemPackages = import ../packages.nix {
    inherit pkgs lib;
    exclude_packages = cfg.nixos.exclude_packages;
  };

  homebrew = {
    enable = true;
    inherit (casks) casks;
  };
}
