{
  flake.homeModules.agentic-tools-skill-creator =
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

      cfg = config.dsqr.home.agentic-tools.skill-creator;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.skill-creator = {
        enable = mkEnableOption "skill-creator agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.skill-creator;
          description = "skill-creator skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/skill-creator".source = cfg.package;
          ".claude/skills/skill-creator".source = cfg.package;
          ".config/codex/skills/skill-creator".source = cfg.package;
        };
      };
    };
}
