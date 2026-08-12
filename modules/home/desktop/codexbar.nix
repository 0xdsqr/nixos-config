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
      inherit (lib.types) str;

      cfg = config.dsqr.home.desktop.codexbar;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      options.dsqr.home.desktop.codexbar = {
        enable = mkEnableOption "CodexBar desktop integration";

        launchd.enable = mkEnableOption "launchd integration for CodexBar" // {
          default = true;
        };

        applicationPath = mkOption {
          type = str;
          default = "/Applications/CodexBar.app";
          description = "Path to the CodexBar application bundle.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isDarwin;
          message = "dsqr.home.desktop.codexbar requires Darwin.";
        };

        launchd.agents.codexbar = mkIf (isDarwin && cfg.launchd.enable) {
          enable = true;
          config = {
            ProgramArguments = [ "${cfg.applicationPath}/Contents/MacOS/CodexBar" ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Interactive";
            EnvironmentVariables.PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin";
          };
        };
      };
    };
}
