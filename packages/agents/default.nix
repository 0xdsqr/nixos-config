{ inputs, ... }:
let
  opencodeFor =
    system:
    let
      upstream = inputs.opencode.packages.${system}.opencode;
      fixedNodeModulesHashes = {
        "aarch64-darwin" = {
          "2.2.7+72616be" = "sha256-3n2v8rGXBZTQCZEsI3N/6sBYmnjPcEUwi7KwRBr21SE=";
        };
      };
      fixedHash = fixedNodeModulesHashes.${system}.${upstream.version} or null;
    in
    if fixedHash == null then
      upstream
    else
      upstream.override { node_modules = upstream.node_modules.override { hash = fixedHash; }; };
in
{
  perSystem = { pkgs, system, ... }: {
    packages = {
      inherit
        (
          (import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          })
        )
        claude-code
        ;
      codex = pkgs.callPackage ./codex/cli.nix { };
      opencode = opencodeFor system;
      pi = pkgs.callPackage ./pi/package.nix { };
      inherit (pkgs) t3code;
    };
  };

  flake.overlays = {
    codex = final: _: { codex = final.callPackage ./codex/cli.nix { }; };
    opencode =
      final: prev:
      (inputs.opencode.overlays.default final prev) // { opencode = opencodeFor final.stdenv.hostPlatform.system; };
    pi = final: _: { pi-coding-agent = final.callPackage ./pi/package.nix { }; };
  };
}
