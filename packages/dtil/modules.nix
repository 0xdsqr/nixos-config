{ lib }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) elem filter;
  inherit (lib.strings) hasSuffix;
in
{
  collectNix =
    {
      dir,
      ignoredNames ? [ ],
      ignoredFiles ? [ ],
    }:
    let
      defaultIgnoredFiles = [ (dir + "/default.nix") ];
    in
    filter (
      path:
      let
        name = builtins.baseNameOf path;
      in
      hasSuffix ".nix" path && !(elem name ignoredNames) && !(elem path (defaultIgnoredFiles ++ ignoredFiles))
    ) (listFilesRecursive dir);
}
