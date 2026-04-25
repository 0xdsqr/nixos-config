{ lib, moduleLocation, ... }:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf unspecified;
in
{
  options.flake.hostDefinitions = mkOption {
    type = lazyAttrsOf unspecified;
    default = { };
    description = "Resolved host metadata keyed by host name.";
  };

  options.flake.darwinConfigurations = mkOption {
    type = lazyAttrsOf unspecified;
    default = { };
    description = "Darwin system configurations.";
  };

  options.flake.commonModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = { };
    apply = mapAttrs (
      name: value: {
        _file = "${toString moduleLocation}#commonModules.${name}";
        imports = singleton value;
      }
    );
    description = "Modules shared between NixOS and Darwin.";
  };

  options.flake.darwinModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = { };
    apply = mapAttrs (
      name: value: {
        _file = "${toString moduleLocation}#darwinModules.${name}";
        imports = singleton value;
      }
    );
    description = "Darwin modules.";
  };
}
