_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.codex = pkgs.callPackage ./package.nix { };
    };

  flake.overlays.codex = final: prev: { codex = final.callPackage ./package.nix { inherit (prev) codex; }; };
}
