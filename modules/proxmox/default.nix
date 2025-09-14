{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import ./time-zone.nix)
    (import ./boot-loader.nix)
    (import ./services.nix)
    (import ./security.nix)
  ];
}
