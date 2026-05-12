{
  flake.homeModules.agentic-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) listToAttrs;
      inherit (lib.lists) concatMap;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf str;

      cfg = config.dsqr.home.agentic-tools;

      installPaths = [
        ".agents/skills"
        ".claude/skills"
        ".config/codex/skills"
      ];

      skillEntries = concatMap (
        name:
        let
          drv = pkgs.agentic-tools.${name};
        in
        map (prefix: {
          name = "${prefix}/${name}";
          value.source = drv;
        }) installPaths
      ) cfg.skills;
    in
    {
      options.dsqr.home.agentic-tools = {
        enable = mkEnableOption "Agentic-tools skill set for pi / codex / claude";

        skills = mkOption {
          type = listOf str;
          default = [
            "browser-tools"
            "vscode"
          ];
          description = "Skill names from pkgs.agentic-tools to symlink into the shared skill paths.";
        };
      };

      config = mkIf cfg.enable { home.file = listToAttrs skillEntries; };
    };
}
