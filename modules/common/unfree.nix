{ ... }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib.lists) elem;
  inherit (lib.options) mkOption;
  inherit (lib.strings) getName;
  inherit (lib.types) listOf str;
in
{
  options.allowedUnfreePackageNames = mkOption {
    type = listOf str;
    default = [
      "vault-bin"
      "vscode"
    ];
    description = "list of unfree nix package names to allow";
    example = [
      "vault-bin"
      "vscode"
    ];
  };

  config.nixpkgs.config.allowUnfreePredicate =
    package: elem (getName package) config.allowedUnfreePackageNames;
}
