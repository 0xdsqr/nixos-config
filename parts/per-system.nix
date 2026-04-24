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
      buildRef = self.shortRev or (if self ? lastModifiedDate then builtins.substring 0 8 self.lastModifiedDate else "dev");
      mgmtVersion =
        let
          baseVersion = "0.1.0";
        in
        "${baseVersion}+${buildRef}";
      versionz = pkgs.callPackage ./../packages/versionz {
        version = buildRef;
        packageVersion = "0.1.0+${buildRef}";
      };
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
      packages.versionz = versionz;

      formatter = treefmtEval.config.build.wrapper;

      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          mgmt
          versionz
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
