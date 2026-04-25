{
  flake.darwinModules.spotify =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      homebrew.casks = singleton "spotify";
    };
}
