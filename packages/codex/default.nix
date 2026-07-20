{ lib, ... }: {
  # The Codex CLI and CodexBar share one package module. CodexBar remains
  # Darwin-only, while its overlay is available on every system.
  perSystem = { pkgs, system, ... }: {
    packages = {
      codex = pkgs.callPackage ./cli.nix { };
    }
    // lib.optionalAttrs (lib.strings.hasSuffix "darwin" system) { codexbar = pkgs.callPackage ./bar.nix { }; };
  };

  flake.overlays = {
    codex = final: prev: { codex = final.callPackage ./cli.nix { inherit (prev) codex; }; };
    codexbar = final: _: { codexbar = final.callPackage ./bar.nix { }; };
  };
}
