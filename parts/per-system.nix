{ inputs, self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem =
    { system, ... }:
    let
      treefmtEval = inputs.treefmt-nix.lib.evalModule (import inputs.nixpkgs { inherit system; }) ./../treefmt.nix;
    in
    {
      formatter = treefmtEval.config.build.wrapper;

      checks = {
        formatting = treefmtEval.config.build.check self;
      };

      devShells.default = import ./../devshell.nix {
        inherit system;
        inherit (inputs) agenix;
        inherit (inputs) nixpkgs;
      };
    };
}
