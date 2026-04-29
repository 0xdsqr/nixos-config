{
  flake.darwinModules.docker =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.docker;
    in
    {
      options.dsqr.darwin.desktop.docker = {
        enable = mkEnableOption "Docker Desktop" // {
          default = true;
        };

        package = mkOption {
          type = str;
          default = "docker-desktop";
          description = "Homebrew cask to install for Docker Desktop.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
