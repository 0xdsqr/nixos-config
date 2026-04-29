{
  flake.commonModules.unfree =
    { config, lib, ... }:
    let
      inherit (lib) getName;
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.allowedUnfreePackageNames = mkOption {
        type = listOf str;
        default = [ ];
        description = "List of unfree nix package names to allow.";
        example = [
          "claude-code"
          "google-chrome"
        ];
      };

      config = {
        allowedUnfreePackageNames = [
          "claude-code"
          "vault-bin"
        ];

        nixpkgs.config.allowUnfreePredicate = package: elem (getName package) config.allowedUnfreePackageNames;
      };
    };
}
