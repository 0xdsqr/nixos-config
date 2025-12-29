inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.eevee;
  packages = import ../packages.nix {
    inherit pkgs lib;
    exclude_packages = cfg.nixos.exclude_packages;
  };
in
{
  imports = [
    (import ./system.nix)
    (import ./1password.nix)
    (import ./containers.nix)
  ];
}
