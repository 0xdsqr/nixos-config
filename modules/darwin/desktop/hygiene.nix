{
  flake.darwinModules."desktop-hygiene" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.hygiene;
    in
    {
      options.dsqr.darwin.desktop.hygiene.enable = mkEnableOption "desktop security and privacy defaults";

      config = mkIf cfg.enable {
        system.defaults.loginwindow = {
          DisableConsoleAccess = true;
          GuestEnabled = false;
        };

        system.defaults.CustomSystemPreferences."com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 0;
        };

        system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
        system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

        system.defaults.CustomSystemPreferences."com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
          allowIdentifierForAdvertising = false;
          forceLimitAdTracking = true;
          personalizedAdsMigrated = false;
        };
      };
    };
}
