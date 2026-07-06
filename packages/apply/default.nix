{ config, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      apply = pkgs.callPackage ./package.nix { inherit (config.flake) hostDefinitions; };
    in
    {
      packages.apply = apply;
      packages.default = apply;

      apps.apply = {
        type = "app";
        program = "${apply}/bin/apply";
        meta.description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      };
    };
}
