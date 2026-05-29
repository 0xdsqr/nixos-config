{
  flake.darwinModules.lapdog =
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
      cfg = config.dsqr.darwin.desktop.lapdog;
    in
    {
      options.dsqr.darwin.desktop.lapdog = {
        enable = mkEnableOption "Datadog Lapdog CLI";

        package = mkOption {
          type = str;
          default = "datadog/lapdog/lapdog";
          description = "Homebrew formula to install for Datadog Lapdog.";
        };

        tapRepository = mkOption {
          type = str;
          default = "datadog/homebrew-lapdog";
          description = ''
            Homebrew tap repository path used by nix-homebrew.

            Homebrew exposes this as the datadog/lapdog tap, but the immutable
            tap directory needs the repository name, including the homebrew-
            prefix.
          '';
        };
      };

      config = mkIf cfg.enable {
        homebrew.brews = singleton cfg.package;
        nix-homebrew.taps.${cfg.tapRepository} = inputs.datadog-lapdog;
      };
    };
}
