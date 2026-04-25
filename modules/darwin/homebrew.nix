{
  flake.darwinModules.homebrew =
    { config, inputs, ... }:
    let
      inherit (config.system) primaryUser;
    in
    {
      homebrew.enable = true;

      nix-homebrew = {
        enable = true;
        autoMigrate = true;
        user = primaryUser;

        taps."homebrew/homebrew-core" = inputs."homebrew-core";
        taps."homebrew/homebrew-cask" = inputs."homebrew-cask";

        mutableTaps = false;
      };
    };
}
