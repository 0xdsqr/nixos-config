{ inputs, lib, ... }: {
  perSystem = { pkgs, system, ... }: {
    packages = {
      claude-code =
        (import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }).callPackage
          ./claude-code/package.nix
          { };
      codex = pkgs.callPackage ./codex/cli.nix { };
      pi = pkgs.callPackage ./pi/package.nix { };
    }
    // lib.optionalAttrs (lib.strings.hasSuffix "darwin" system) { codexbar = pkgs.callPackage ./codex/bar.nix { }; };
  };

  flake.overlays = {
    claude-code = final: prev: {
      claude-code = final.callPackage ./claude-code/package.nix { inherit (prev) claude-code; };
    };
    codex = final: prev: { codex = final.callPackage ./codex/cli.nix { inherit (prev) codex; }; };
    codexbar = final: _: { codexbar = final.callPackage ./codex/bar.nix { }; };
    pi = final: _: { pi-coding-agent = final.callPackage ./pi/package.nix { }; };
  };
}
