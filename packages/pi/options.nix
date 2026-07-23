{ lib, pkgs }:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) package;
  extensions = import ./extensions;
in
{
  enable = mkEnableOption "Pi coding agent";

  package = mkOption {
    type = package;
    default = pkgs.pi-coding-agent;
    description = "Pi coding agent package to install.";
  };

  themes = mapAttrs (name: _: {
    enable = mkEnableOption "the ${name} Pi theme" // {
      default = true;
    };
  }) (import ./themes);

  extensions = mapAttrs (name: definition: {
    enable = mkEnableOption "the ${name} Pi extension" // {
      default = definition.enableByDefault or false;
    };
  }) extensions;
}
