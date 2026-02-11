inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../common/nixpkgs.nix
    (import ./time-zone.nix)
    (import ./boot-loader.nix)
    (import ./services.nix)
    (import ./security.nix)
    (import ./networking.nix)
    (import ./nix-settings.nix inputs)
  ];
}
