{
  flake.darwinModules."desktop-file-explorer" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.desktop.fileExplorer;
    in
    {
      options.dsqr.darwin.desktop.fileExplorer.enable = mkEnableOption "Finder and file explorer defaults";

      config = mkIf cfg.enable {
        system.defaults.NSGlobalDomain = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          "com.apple.springing.delay" = 0.0;
          "com.apple.springing.enabled" = true;
        };

        system.defaults.CustomSystemPreferences."com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        system.defaults.finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXEnableExtensionChangeWarning = true;
          FXPreferredViewStyle = "Nlsv";
          FXRemoveOldTrashItems = true;
          NewWindowTarget = "Home";
          QuitMenuItem = true;
          ShowExternalHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowPathbar = true;
          ShowRemovableMediaOnDesktop = true;
          ShowStatusBar = true;
          _FXShowPosixPathInTitle = true;
          _FXSortFoldersFirst = true;
          _FXSortFoldersFirstOnDesktop = false;
        };

        system.defaults.CustomSystemPreferences."com.apple.finder" = {
          DisableAllAnimations = true;
          FXArrangeGroupViewBy = "Name";
          FxDefaultSearchScope = "SCcf";
          WarnOnEmptyTrash = false;
        };

        system.activationScripts.script.text = mkAfter /* bash */ ''
          ${config.system.activationScripts.unhide-library.text}
        '';

        system.activationScripts.unhide-library.text = /* bash */ ''
          echo "unhiding user Library..."
          /usr/bin/chflags nohidden ${lib.escapeShellArg "/Users/${config.system.primaryUser}/Library"}
        '';
      };
    };
}
