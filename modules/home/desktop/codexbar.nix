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
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.meta) getExe;
      inherit (lib.types) package;

      cfg = config.dsqr.home.desktop.codexbar;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      options.dsqr.home.desktop.codexbar = {
        enable = mkEnableOption "CodexBar desktop integration";

        launchd.enable = mkEnableOption "launchd integration for CodexBar" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.codexbar;
          description = "CodexBar package to install.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isDarwin;
          message = "dsqr.home.desktop.codexbar requires Darwin.";
        };

        home.packages = mkIf isDarwin (singleton cfg.package);

        launchd.agents.codexbar = mkIf (isDarwin && cfg.launchd.enable) {
          enable = true;
          config = {
            ProgramArguments = [ (getExe cfg.package) ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Interactive";
          };
        };
      };
    };
}
