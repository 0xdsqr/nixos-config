{
  flake.darwinModules.homebrew =
    { config, inputs, ... }:
    {
      homebrew.enable = true;

      nix-homebrew = {
        enable = true;
        autoMigrate = true;
        user = config.system.primaryUser;

        taps."homebrew/homebrew-core" = inputs."homebrew-core";
        taps."homebrew/homebrew-cask" = inputs."homebrew-cask";

        mutableTaps = false;
      };
    };
}
