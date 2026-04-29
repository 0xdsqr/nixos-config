{
  flake.darwinModules."desktop-system" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.system;
    in
    {
      options.dsqr.darwin.desktop.system.enable = mkEnableOption "desktop system UI defaults";

      config = mkIf cfg.enable {
        system.defaults = {
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
