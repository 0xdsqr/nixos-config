{ inputs, self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, ... }:
    let
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

      packages.moonshot = pkgs.callPackage ../packages/moonshot { };

      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          nil
          nixd
          statix
          treefmtEval.config.build.wrapper
        ];
      };

      devShells.moonshot = pkgs.mkShellNoCC {
        packages = with pkgs; [
          go
        ];
      };

      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
