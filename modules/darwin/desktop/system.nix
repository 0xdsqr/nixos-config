{
  flake.darwinModules."desktop-system" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.system;
      statusClockCfg = config.dsqr.darwin.desktop.statusClock;
    in
    {
      options.dsqr.darwin.desktop.system.enable = mkEnableOption "desktop system UI defaults";
      options.dsqr.darwin.desktop.statusClock.enable = mkEnableOption "Status Clock Mac App Store app via mas";

      config = {
        homebrew.masApps = mkIf statusClockCfg.enable { "Status Clock" = 552792489; };

        system.defaults = mkIf cfg.enable {
          menuExtraClock = {
            Show24Hour = true;
            ShowSeconds = true;
          };

          controlcenter = {
            BatteryShowPercentage = true;
            Bluetooth = true;
          };

          screencapture.location = "~/Downloads/Screenshots";

          NSGlobalDomain.AppleICUForce24HourTime = true;

          trackpad = {
            Clicking = false;
            Dragging = false;
          };
        };
      };
    };
}
