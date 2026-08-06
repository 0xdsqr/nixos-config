_: {
  perSystem = { pkgs, ... }: { packages.xurl = pkgs.callPackage ./package.nix { }; };

  flake.overlays.xurl = final: _: { xurl = final.callPackage ./package.nix { }; };
}
