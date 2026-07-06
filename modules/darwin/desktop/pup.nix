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
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) nullOr str;
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

        site = mkOption {
          type = nullOr str;
          default = null;
          example = "us5.datadoghq.com";
          description = ''
            Datadog site pup targets, exported as DD_SITE.

            When null, pup uses its own default (datadoghq.com). DD_SITE takes
            precedence over ~/.config/pup/config.yaml. Note this variable is
            read by other Datadog CLIs as well.
          '';
        };
      };

      config = mkIf cfg.enable {
        homebrew.brews = singleton cfg.package;
        nix-homebrew.taps.${cfg.tapRepository} = inputs.datadog-pup;
        environment.variables = optionalAttrs (cfg.site != null) { DD_SITE = cfg.site; };
      };
    };
}
