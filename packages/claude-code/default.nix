{ inputs, ... }: {
  # claude-code is unfree; build the flake output against an allowUnfree nixpkgs.
  perSystem = { system, ... }: {
    packages.claude-code =
      (import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }).callPackage
        ./package.nix
        { };
  };

  flake.overlays.claude-code = final: prev: {
    claude-code = final.callPackage ./package.nix { inherit (prev) claude-code; };
  };
}
