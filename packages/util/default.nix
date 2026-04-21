{ lib }:
let
  inherit (lib.attrsets) nameValuePair;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter;
  inherit (lib.strings) hasSuffix removeSuffix;

  nixFiles = filter (file: hasSuffix ".nix" file && builtins.baseNameOf file != "default.nix") (listFilesRecursive ./.);
in
builtins.listToAttrs (map (file: nameValuePair (removeSuffix ".nix" (builtins.baseNameOf file)) (import file)) nixFiles)
