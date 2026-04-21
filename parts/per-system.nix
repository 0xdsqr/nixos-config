{ inputs, self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { config, pkgs, ... }:
    let
      dick = pkgs.callPackage ../packages/dick { };
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";

        # Formats Nix files consistently.
        programs.nixfmt = {
          enable = true;
          strict = true;
          width = 120;
        };

        # Finds and removes unused Nix code.
        programs.deadnix.enable = true;
        # Flags style issues and simplification opportunities in Nix code.
        programs.statix.enable = true;
      };
    in
    {
      formatter = treefmtEval.config.build.wrapper;

      packages = {
        inherit dick;
        default = dick;
      };

      apps = {
        dick = {
          type = "app";
          program = "${dick}/bin/dick";
        };

        default = config.apps.dick;
      };

      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          dick
          nil
          nixd
          statix
          treefmtEval.config.build.wrapper
        ];
      };

      devShells.dick = pkgs.mkShellNoCC {
        packages = with pkgs; [
          go
          dick
        ];
      };

      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
