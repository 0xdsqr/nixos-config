{
  flake.darwinModules.homebrew =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) bool nullOr str;

      cfg = config.dsqr.darwin.homebrew;
    in
    {
      options.dsqr.darwin.homebrew = {
        enable = mkEnableOption "Darwin Homebrew and nix-homebrew management";

        user = mkOption {
          type = nullOr str;
          default = null;
          description = "Darwin user that owns the managed Homebrew prefix.";
        };

        nixHomebrew = {
          enable = mkEnableOption "nix-homebrew ownership of the Homebrew installation" // {
            default = true;
          };

          autoMigrate = mkOption {
            type = bool;
            default = true;
            description = "Automatically migrate an existing Homebrew installation into nix-homebrew.";
          };

          mutableTaps = mkOption {
            type = bool;
            default = false;
            description = "Whether Homebrew taps may be mutated outside the declarative config.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = !cfg.nixHomebrew.enable || cfg.user != null;
            message = "dsqr.darwin.homebrew.user must be set when nix-homebrew management is enabled.";
          }
        ];

        homebrew.enable = true;

        nix-homebrew = mkIf cfg.nixHomebrew.enable {
          enable = true;
          inherit (cfg.nixHomebrew) autoMigrate;
          inherit (cfg) user;

          taps."homebrew/homebrew-core" = inputs."homebrew-core";
          taps."homebrew/homebrew-cask" = inputs."homebrew-cask";

          inherit (cfg.nixHomebrew) mutableTaps;
        };
      };
    };
}
