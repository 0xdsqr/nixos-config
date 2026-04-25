_: {
  flake.homeModules.exo =
    { exo, pkgs, ... }:
    let
      exoPackage = exo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [
        exoPackage
        pkgs.uv
      ];
    };

  flake.homeModules.ollama =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ollama ];
    };
}
