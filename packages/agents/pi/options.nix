{ lib, pkgs }:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) anything attrsOf package;
  extensions = import ./extensions;
in
{
  enable = mkEnableOption "Pi coding agent";

  package = mkOption {
    type = package;
    default = pkgs.pi-coding-agent;
    description = "Pi coding agent package to install.";
  };

  models = mkOption {
    type = attrsOf anything;
    default = { };
    description = "Nix-managed Pi custom providers and models written to models.json.";
  };

  themes = mapAttrs (name: _: {
    enable = mkEnableOption "the ${name} Pi theme" // {
      default = true;
    };
  }) (import ./themes);

  extensions = mapAttrs (
    name: definition:
    {
      enable = mkEnableOption "the ${name} Pi extension" // {
        default = definition.enableByDefault or false;
      };
    }
    // optionalAttrs (definition ? settings) {
      settings = mkOption {
        type = attrsOf anything;
        default = definition.settings;
        description = "Nix-managed settings for the ${name} Pi extension.";
      };
    }
  ) extensions;
}
