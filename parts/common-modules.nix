{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  inherit (nixLib.attrsets) nameValuePair;
  inherit (nixLib.attrsets) filterAttrs;
  inherit (nixLib.strings) hasSuffix removeSuffix;

  commonFiles =
    builtins.readDir ./../modules/common
    |> filterAttrs (name: kind: kind == "regular" && hasSuffix ".nix" name);

  importedCommonModules = builtins.listToAttrs (
    builtins.map (
      name:
      nameValuePair (removeSuffix ".nix" name) (import (./../modules/common + "/${name}") { inherit self inputs; })
    ) (builtins.attrNames commonFiles)
  );
in
{
  flake.commonModules = importedCommonModules;
}
