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
      moonshot = pkgs.callPackage ../packages/moonshot { };
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
        inherit moonshot;
        default = moonshot;
      };

      apps = {
        moonshot = {
          type = "app";
          program = "${moonshot}/bin/moonshot";
        };

        default = config.apps.moonshot;
      };

      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          moonshot
          nil
          nixd
          statix
          treefmtEval.config.build.wrapper
        ];
      };

      devShells.moonshot = pkgs.mkShellNoCC {
        packages = with pkgs; [
          go
          moonshot
        ];
      };

      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
