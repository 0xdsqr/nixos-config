{
  flake.darwinModules."window-manager" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.windowManager;
    in
    {
      options.dsqr.darwin.desktop.windowManager.enable = mkEnableOption "desktop window-manager defaults";

      config = mkIf cfg.enable {
        system.defaults.NSGlobalDomain = {
          ApplePressAndHoldEnabled = false;
          AppleShowScrollBars = "WhenScrolling";
          AppleWindowTabbingMode = "always";
          InitialKeyRepeat = 10;
          KeyRepeat = 1;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticInlinePredictionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
        };

        system.defaults.CustomSystemPreferences."com.apple.dock".workspaces-auto-swoosh = false;
        system.defaults.CustomSystemPreferences."com.apple.Accessibility".ReduceMotionEnabled = 1;
        system.defaults.WindowManager.AppWindowGroupingBehavior = false;
      };
    };
}
