lib:
let
  inherit (lib) mkAfter;
  inherit (lib.attrsets) attrValues;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) elem filter;
  inherit (lib.strings) hasPrefix hasSuffix;

  collectNix =
    {
      dir,
      ignoredNames ? [ ],
      ignoredFiles ? [ ],
      ignoredDirectories ? [ ],
    }:
    filter (
      path:
      let
        name = builtins.baseNameOf path;
        pathString = toString path;
      in
      hasSuffix ".nix" pathString
      && !(elem name ignoredNames)
      && !(elem path ignoredFiles)
      && !(builtins.any (ignoredDir: hasPrefix "${toString ignoredDir}/" pathString) ignoredDirectories)
    ) (listFilesRecursive dir);

  collectHostNix =
    {
      dir,
      ignoredNames ? [ ],
      ignoredFiles ? [ ],
    }:
    collectNix {
      inherit dir ignoredNames;
      ignoredFiles = [ (dir + "/default.nix") ] ++ ignoredFiles;
    };

  selectModules = modules: names: builtins.map (name: modules.${name}) names;

  filterSelected = names: excluded: builtins.filter (name: !(elem name excluded)) names;

  collectHostModules =
    {
      commonModules,
      platformModules,
      homeModules,
      platform ? [ ],
      home ? [ ],
      excludePlatform ? [ ],
      excludeHome ? [ ],
      extraPlatform ? [ ],
      extraHome ? [ ],
      extraModules ? [ ],
    }:
    attrValues commonModules
    ++ selectModules platformModules (filterSelected (platform ++ extraPlatform) excludePlatform)
    ++ [
      { home-manager.sharedModules = mkAfter (selectModules homeModules (filterSelected (home ++ extraHome) excludeHome)); }
    ]
    ++ extraModules;
in
{
  inherit collectNix collectHostNix collectHostModules;
}
