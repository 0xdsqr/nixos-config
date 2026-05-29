{ config, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      apply = pkgs.callPackage ./apply {
        inherit (config.flake) hostDefinitions;
        repoRoot = ../.;
      };
    in
    {
      packages = {
        inherit apply;

        default = apply;
      };

      apps.apply = {
        type = "app";
        program = "${apply}/bin/apply";
        meta.description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      };
    };
}
