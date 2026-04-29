{
  flake.darwinModules.homebrew =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) str;

      cfg = config.dsqr.darwin.homebrew;
    in
    {
      options.dsqr.darwin.homebrew.user = mkOption {
        type = str;
        default = config.dsqr.darwin.personal.user.name;
        description = "Darwin user that owns the managed Homebrew prefix.";
      };

      config = {
        homebrew.enable = true;

        nix-homebrew = {
          enable = true;
          autoMigrate = true;
          inherit (cfg) user;

          taps."homebrew/homebrew-core" = inputs."homebrew-core";
          taps."homebrew/homebrew-cask" = inputs."homebrew-cask";

          mutableTaps = false;
        };
      };
    };
}
