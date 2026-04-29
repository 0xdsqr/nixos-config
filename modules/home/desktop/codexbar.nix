{ inputs, ... }:
{
  flake.homeModules.codexbar =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.desktop.codexbar;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      imports = singleton inputs.nix-steipete-tools.homeManagerModules.codexbar;

      options.dsqr.home.desktop.codexbar = {
        enable = mkEnableOption "CodexBar desktop integration";

        launchd.enable = mkEnableOption "launchd integration for CodexBar" // {
          default = true;
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isDarwin;
          message = "dsqr.home.desktop.codexbar requires Darwin.";
        };

        programs.codexbar.enable = mkIf isDarwin true;
        programs.codexbar.launchd.enable = mkIf isDarwin cfg.launchd.enable;
      };
    };
}
