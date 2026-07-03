{
  flake.darwinModules.pup =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.pup;
    in
    {
      options.dsqr.darwin.desktop.pup = {
        enable = mkEnableOption "Datadog Pup CLI";

        package = mkOption {
          type = str;
          default = "datadog-labs/pack/pup";
          description = "Homebrew formula to install for Datadog Pup.";
        };

        tapRepository = mkOption {
          type = str;
          default = "datadog-labs/homebrew-pack";
          description = ''
            Homebrew tap repository path used by nix-homebrew.

            Homebrew exposes this as the datadog-labs/pack tap, but the immutable
            tap directory needs the repository name, including the homebrew-
            prefix.
          '';
        };
      };

      config = mkIf cfg.enable {
        homebrew.brews = singleton cfg.package;
        nix-homebrew.taps.${cfg.tapRepository} = inputs.datadog-pup;
      };
    };
}
