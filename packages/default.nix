{ config, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      apply = pkgs.callPackage ./apply {
        inherit (config.flake) hostDefinitions;
        repoRoot = ../.;
      };
      fast-workspace-switch = pkgs.callPackage ./fast-workspace-switch { };
    in
    {
      packages = {
        inherit apply;
        inherit fast-workspace-switch;

        default = apply;
      };

      apps.apply = {
        type = "app";
        program = "${apply}/bin/apply";
        meta.description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      };
    };
}
