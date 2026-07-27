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
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) enum listOf;

      cfg = config.dsqr.home.agentSkills;
      skills = import ../../packages/agents/skills { inherit inputs; };

      enabledFor = target: filterAttrs (name: _: elem target cfg.${name}.targets) skills;
      linksFor =
        prefix: skillSet: mapAttrs' (name: source: lib.nameValuePair "${prefix}/${name}" { inherit source; }) skillSet;
    in
    {
      options.dsqr.home.agentSkills = mapAttrs (name: _: {
        targets = mkOption {
          type = listOf (enum [
            "agents"
            "claude"
            "pi"
          ]);
          default = [ ];
          description = "Agent runtimes that can discover the ${name} skill.";
        };
      }) skills;

      config = {
        home.file = linksFor ".agents/skills" (enabledFor "agents") // linksFor ".claude/skills" (enabledFor "claude");

        xdg.configFile = linksFor "claude-code/skills" (enabledFor "claude") // linksFor "pi/agent/skills" (enabledFor "pi");
      };
    };
}
