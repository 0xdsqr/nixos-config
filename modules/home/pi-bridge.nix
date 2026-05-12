{
  flake.homeModules.pi-bridge =
    { config, lib, ... }:
    let
      inherit (lib.attrsets) filterAttrs listToAttrs mapAttrsToList;
      inherit (lib.lists) concatLists;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf str;

      cfg = config.dsqr.home.pi-bridge;

      enabledSkills = filterAttrs (_: s: s.enable) config.programs.pi.skills;

      mkLinks =
        prefix:
        mapAttrsToList (name: skill: {
          name = "${prefix}/${name}";
          value.source = skill.package;
        }) enabledSkills;
    in
    {
      options.dsqr.home.pi-bridge = {
        enable = mkEnableOption "mirror enabled pi skills into claude-code and codex discovery paths" // {
          default = true;
        };

        paths = mkOption {
          type = listOf str;
          default = [
            ".claude/skills"
            ".config/codex/skills"
          ];
          description = "Additional directories to mirror each enabled pi skill into.";
        };
      };

      config = mkIf cfg.enable { home.file = listToAttrs (concatLists (map mkLinks cfg.paths)); };
    };
}
