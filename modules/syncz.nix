_:
{
  perSystem =
    { pkgs, system, ... }:
    let
      synczPackage = pkgs.callPackage ../packages/syncz/default.nix { inherit system; };
    in
    {
      packages.syncz = synczPackage;

      apps.syncz = {
        type = "app";
        program = "${synczPackage}/bin/syncz";
      };
    };
}
