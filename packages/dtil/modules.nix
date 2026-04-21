{ lib }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) elem filter;
  inherit (lib.strings) hasSuffix;
in
{
  collectLocalNixModules =
    {
      dir,
      ignoredNames ? [ ],
    }:
    let
      defaultIgnoredNames = [
        "default.nix"
        "meta.nix"
      ];
    in
    filter (
      path:
      let
        name = builtins.baseNameOf path;
      in
      hasSuffix ".nix" path && !(elem name (defaultIgnoredNames ++ ignoredNames))
    ) (listFilesRecursive dir);
}
