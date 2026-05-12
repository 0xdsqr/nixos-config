{
  flake.homeModules.agentic-tools-browser-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.agentic-tools.browser-tools;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.browser-tools = {
        enable = mkEnableOption "browser-tools agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.browser-tools;
          description = "browser-tools skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/browser-tools".source = cfg.package;
          ".claude/skills/browser-tools".source = cfg.package;
          ".config/codex/skills/browser-tools".source = cfg.package;
        };
      };
    };
}
