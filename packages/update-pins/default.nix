_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.update-pins = pkgs.callPackage ./package.nix { };
    };
}
