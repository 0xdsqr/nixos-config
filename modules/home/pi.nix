{
  flake.homeModules.pi =
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
      inherit (lib.types) package;

      cfg = config.programs.pi;
    in
    {
      options.programs.pi = {
        enable = mkEnableOption "Pi coding agent";

        package = mkOption {
          type = package;
          default = pkgs.pi-coding-agent;
          description = "Pi coding agent package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent";
      };
    };
}
