{
  flake.homeModules.agent-skills =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrs mapAttrs';
      inherit (lib.lists) elem optional;
      inherit (lib.options) mkOption;
      inherit (lib.types) enum listOf;

      cfg = config.dsqr.home.agentSkills;
      skills = import ../../packages/agents/skills { inherit inputs; };

      targetType = listOf (enum [
        "agents"
        "claude"
        "codex"
        "opencode"
        "pi"
      ]);

      enabledFor = target: filterAttrs (name: _: elem target cfg.${name}.targets) skills;
      linksFor =
        prefix: skillSet: mapAttrs' (name: source: lib.nameValuePair "${prefix}/${name}" { inherit source; }) skillSet;
    in
    {
      options.dsqr.home.agentSkills =
        mapAttrs (name: _: {
          targets = mkOption {
            type = targetType;
            default = cfg.defaultTargets;
            defaultText = lib.literalExpression "config.dsqr.home.agentSkills.defaultTargets";
            description = "Agent runtimes that can discover the ${name} skill.";
          };
        }) skills
        // {
          defaultTargets = mkOption {
            type = targetType;
            # Every catalog skill reaches every agent this host enables; Codex, Pi,
            # and OpenCode all read the shared `agents` root.
            default =
              optional config.dsqr.home.claudeCode.enable "claude"
              ++ optional (config.dsqr.home.codex.enable || config.dsqr.home.opencode.enable || config.programs.pi.enable) "agents";
            defaultText = lib.literalMD "`claude` when Claude Code is enabled, plus `agents` when Codex, OpenCode, or Pi is enabled";
            description = "Targets for catalog skills that do not set their own `targets`.";
          };
        };

      config = {
        home.file = linksFor ".agents/skills" (enabledFor "agents");

        xdg.configFile =
          linksFor "claude-code/skills" (enabledFor "claude")
          // linksFor "codex/skills" (enabledFor "codex")
          // linksFor "opencode/skills" (enabledFor "opencode")
          // linksFor "pi/agent/skills" (enabledFor "pi");
      };
    };
}
