{
  flake.darwinModules.excalidraw =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.excalidraw;
    in
    {
      options.dsqr.darwin.desktop.excalidraw = {
        enable = mkEnableOption "Excalidraw desktop app";

        # Excalidraw ships no desktop app of its own. ExcalidrawZ is the
        # community macOS client in homebrew-cask.
        package = mkOption {
          type = str;
          default = "excalidrawz";
          description = "Homebrew cask to install for Excalidraw.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
