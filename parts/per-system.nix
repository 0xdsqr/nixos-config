{ inputs, self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, self', ... }:
    let
      nuForChecks = pkgs.nushell.overrideAttrs (_: {
        doCheck = false;
      });
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
        mgmt =
          pkgs.runCommand "mgmt-check"
            {
              nativeBuildInputs = [
                nuForChecks
                self'.packages.mgmt
                pkgs.gnugrep
              ];
            }
            ''
              export HOME="$TMPDIR/home"
              export XDG_CONFIG_HOME="$TMPDIR/xdg-config"
              export XDG_CACHE_HOME="$TMPDIR/xdg-cache"
              export XDG_DATA_HOME="$TMPDIR/xdg-data"
              mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
              export PATH="${nuForChecks}/bin:$PATH"
              ${self'.packages.mgmt}/bin/mgmt help > help.txt
              ${self'.packages.mgmt}/bin/mgmt version > version.txt

              grep -q "Show this help screen" help.txt
              grep -Eq '^0\.1\.0-' version.txt
              test -f ${self'.packages.mgmt}/share/mgmt/templates/host/meta.nix
              touch "$out"
            '';
      };
    };
}
