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
      claude-code =
        (import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }).callPackage
          ./claude-code/package.nix
          { };
      codex = pkgs.callPackage ./codex/cli.nix { };
      opencode = opencodeFor system;
      pi = pkgs.callPackage ./pi/package.nix { };
      t3code = pkgs.callPackage ./t3code/package.nix { };
    };
  };

  flake.overlays = {
    claude-code = final: prev: {
      claude-code = final.callPackage ./claude-code/package.nix { inherit (prev) claude-code; };
    };
    codex = final: _: { codex = final.callPackage ./codex/cli.nix { }; };
    opencode =
      final: prev:
      (inputs.opencode.overlays.default final prev) // { opencode = opencodeFor final.stdenv.hostPlatform.system; };
    pi = final: _: { pi-coding-agent = final.callPackage ./pi/package.nix { }; };
    t3code = final: prev: { t3code = final.callPackage ./t3code/package.nix { inherit (prev) t3code; }; };
  };
}
