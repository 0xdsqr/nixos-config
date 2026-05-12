{
  flake.homeModules.agentic-tools-vscode =
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

      cfg = config.dsqr.home.agentic-tools.vscode;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.vscode = {
        enable = mkEnableOption "vscode agent skill" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.vscode;
          description = "vscode skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/vscode".source = cfg.package;
          ".claude/skills/vscode".source = cfg.package;
          ".config/codex/skills/vscode".source = cfg.package;
        };
      };
    };
}
