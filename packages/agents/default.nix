{ inputs, ... }: {
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
      opencode = inputs.opencode.packages.${system}.opencode;
      pi = pkgs.callPackage ./pi/package.nix { };
      t3code = pkgs.callPackage ./t3code/package.nix { };
    };
  };

  flake.overlays = {
    claude-code = final: prev: {
      claude-code = final.callPackage ./claude-code/package.nix { inherit (prev) claude-code; };
    };
    codex = final: prev: { codex = final.callPackage ./codex/cli.nix { inherit (prev) codex; }; };
    opencode = inputs.opencode.overlays.default;
    pi = final: _: { pi-coding-agent = final.callPackage ./pi/package.nix { }; };
    t3code = final: prev: { t3code = final.callPackage ./t3code/package.nix { inherit (prev) t3code; }; };
  };
}
