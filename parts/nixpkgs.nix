{ inputs, ... }:
{
  flake.commonModules.nixpkgs =
    { config, ... }:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib) elem getName mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.allowedUnfreePackageNames = mkOption {
        type = listOf str;
        default = [ "vault-bin" ];
        description = "List of unfree nix package names to allow.";
        example = [ "vault-bin" ];
      };

      config = {
        nixpkgs.overlays = builtins.map (name: inputs.${name}.overlays.default) [
          "agenix"
          "darwin"
          "neovim-nightly-overlay"
          "nix-openclaw"
        ];

        nixpkgs.config.allowUnfreePredicate = package: elem (getName package) config.allowedUnfreePackageNames;
      };
    };
}
