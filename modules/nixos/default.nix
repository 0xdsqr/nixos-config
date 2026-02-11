inputs:
{ ... }:
{
  imports = [
    ../common/nixpkgs.nix
    (import ./system.nix)
    (import ./1password.nix)
    (import ./containers.nix)
  ];
}
