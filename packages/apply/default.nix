{ config, inputs, ... }: {
  perSystem =
    { pkgs, system, ... }:
    let
      nix = inputs.determinate.inputs.nix.packages.${system}.default;
      darwin-rebuild = if pkgs.stdenv.hostPlatform.isDarwin then inputs.darwin.packages.${system}.darwin-rebuild else null;
      packageArgs = {
        inherit darwin-rebuild nix;
        inherit (config.flake) hostDefinitions;
        inherit (pkgs) nh;
      };
      apply = pkgs.callPackage ./package.nix packageArgs;
    in
    {
      packages.apply = apply;
      packages.default = apply;

      checks.apply = pkgs.callPackage ./test.nix { inherit (config.flake) hostDefinitions; };

      apps.apply = {
        type = "app";
        program = "${apply}/bin/apply";
        meta.description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      };
    };
}
