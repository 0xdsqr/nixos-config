{
  flake.darwinModules.maccy =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkPackageOption;
      cfg = config.dsqr.darwin.desktop.maccy;
    in
    {
      options.dsqr.darwin.desktop.maccy = {
        enable = mkEnableOption "Maccy clipboard history";

        package = mkPackageOption pkgs "maccy" { };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = singleton cfg.package;

        system.defaults.CustomSystemPreferences."org.p0deje.Maccy" = {
          KeyboardShortcuts_delete = 0;
          KeyboardShortcuts_pin = 0;
          KeyboardShortcuts_popup = ''{"carbonKeyCode":9,"carbonModifiers":4352}'';
          SUEnableAutomaticChecks = 0;
          enabledPasteboardTypes = [
            "public.png"
            "public.file-url"
            "public.utf8-plain-text"
            "public.rtf"
            "public.tiff"
            "public.html"
          ];
          menuIcon = "clipboard";
          popupPosition = "window";
          searchMode = "fuzzy";
          showFooter = 0;
          showSearch = 1;
          showTitle = 0;
        };
      };
    };
}
