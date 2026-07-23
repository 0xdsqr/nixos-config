_: {
  perSystem = { pkgs, ... }: { packages.pi = pkgs.callPackage ./package.nix { }; };

  flake.overlays.pi = final: _: { pi-coding-agent = final.callPackage ./package.nix { }; };
}
