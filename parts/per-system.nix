{ inputs, self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, ... }:
    let
      mgmtVersion =
        let
          buildId = self.shortRev or (if self ? lastModifiedDate then builtins.substring 0 8 self.lastModifiedDate else "dev");
        in
        "0.1.0-${buildId}";
      mgmt = pkgs.callPackage ./../packages/mgmt { version = mgmtVersion; };
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
      packages.mgmt = mgmt;

      formatter = treefmtEval.config.build.wrapper;

      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          mgmt
          deadnix
          nil
          nixd
          statix
          treefmtEval.config.build.wrapper
        ];
      };

      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
