{
  flake.darwinModules."window-manager" = {
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
}
