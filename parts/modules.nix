{ inputs, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  inherit (nixLib.attrsets) nameValuePair;
  inherit (nixLib.filesystem) listFilesRecursive;
  inherit (nixLib.lists) filter;
  inherit (nixLib.strings) hasSuffix removeSuffix;

  importModules =
    dir:
    builtins.listToAttrs (
      map (
        file:
        nameValuePair (removeSuffix ".nix" (builtins.baseNameOf file)) (import file)
      ) (filter (hasSuffix ".nix") (listFilesRecursive dir))
    );

  homeModules = importModules ./../modules/home;
  nixosModules = importModules ./../modules/nixos;
  darwinModules = importModules ./../modules/darwin;
in
{
  flake = {
    lib = nixLib;
    inherit homeModules nixosModules darwinModules;
  };
}
