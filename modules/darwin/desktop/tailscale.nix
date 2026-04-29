{
  flake.darwinModules.tailscale =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.tailscale;
    in
    {
      options.dsqr.darwin.desktop.tailscale = {
        enable = mkEnableOption "Tailscale desktop app" // {
          default = true;
        };

        package = mkOption {
          type = str;
          default = "tailscale-app";
          description = "Homebrew cask to install for Tailscale.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
