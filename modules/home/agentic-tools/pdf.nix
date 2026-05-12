{
  flake.homeModules.agentic-tools-pdf =
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

      cfg = config.dsqr.home.agentic-tools.pdf;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.pdf = {
        enable = mkEnableOption "pdf agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.pdf;
          description = "pdf skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/pdf".source = cfg.package;
          ".claude/skills/pdf".source = cfg.package;
          ".config/codex/skills/pdf".source = cfg.package;
        };
      };
    };
}
