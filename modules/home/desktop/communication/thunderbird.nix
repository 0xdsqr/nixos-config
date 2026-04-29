{
  flake.homeModules.thunderbird =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.desktop.communication.thunderbird;
      inherit (pkgs.stdenv.hostPlatform) isLinux;

      mailMimeTypes = [
        "message/rfc822"
        "x-scheme-handler/mailto"
        "text/calendar"
        "text/x-vcard"
      ];
    in
    {
      options.dsqr.home.desktop.communication.thunderbird = {
        enable = mkEnableOption "Thunderbird desktop app";

        package = mkOption {
          type = package;
          default = pkgs.thunderbird;
          description = "Thunderbird package to install.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isLinux;
          message = "dsqr.home.desktop.communication.thunderbird requires Linux.";
        };

        home.packages = singleton cfg.package;

        xdg.mimeApps.defaultApplications = mkIf isLinux (genAttrs mailMimeTypes (_: singleton "thunderbird.desktop"));
      };
    };
}
