{
  flake.homeModules.agentic-tools-xlsx =
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

      cfg = config.dsqr.home.agentic-tools.xlsx;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.xlsx = {
        enable = mkEnableOption "xlsx agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.xlsx;
          description = "xlsx skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/xlsx".source = cfg.package;
          ".claude/skills/xlsx".source = cfg.package;
          ".config/codex/skills/xlsx".source = cfg.package;
        };
      };
    };
}
