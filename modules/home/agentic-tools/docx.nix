{
  flake.homeModules.agentic-tools-docx =
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

      cfg = config.dsqr.home.agentic-tools.docx;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.docx = {
        enable = mkEnableOption "docx agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.docx;
          description = "docx skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/docx".source = cfg.package;
          ".claude/skills/docx".source = cfg.package;
          ".config/codex/skills/docx".source = cfg.package;
        };
      };
    };
}
