{ lib, ... }:
{
  # Package output is darwin-only; the overlay stays unconditional so pkgs.codexbar
  # resolves everywhere (meta.platforms guards any accidental build).
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (lib.strings.hasSuffix "darwin" system) { packages.codexbar = pkgs.callPackage ./package.nix { }; };

  flake.overlays.codexbar = final: _: { codexbar = final.callPackage ./package.nix { }; };
}
