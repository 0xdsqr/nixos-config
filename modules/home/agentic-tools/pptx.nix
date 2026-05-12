{
  flake.homeModules.agentic-tools-pptx =
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

      cfg = config.dsqr.home.agentic-tools.pptx;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.pptx = {
        enable = mkEnableOption "pptx agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.pptx;
          description = "pptx skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/pptx".source = cfg.package;
          ".claude/skills/pptx".source = cfg.package;
          ".config/codex/skills/pptx".source = cfg.package;
        };
      };
    };
}
