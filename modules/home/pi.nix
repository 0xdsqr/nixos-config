{
  flake.homeModules.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrs
        mapAttrs'
        nameValuePair
        ;
      inherit (lib.lists) singleton unique;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        attrs
        attrsOf
        bool
        listOf
        package
        str
        submodule
        ;

      cfg = config.programs.pi;
      skillManifest = import ../../packages/pi/manifest.nix;
      packagedSkills = skillManifest.pi // skillManifest.anthropic // skillManifest.custom;
      defaultSkills = mapAttrs (name: _info: {
        enable = true;
        package = pkgs.pi-skills.${name};
      }) packagedSkills;
    in
    {
      options.programs.pi = {
        enable = mkEnableOption "Pi coding agent";

        package = mkOption {
          type = package;
          default = pkgs.pi-coding-agent;
          description = "Pi coding agent package to install.";
        };

        settings = mkOption {
          type = attrs;
          default = {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.4";
            defaultThinkingLevel = "high";
          };
          description = ''
            Contents of `~/.config/pi/agent/settings.json`. The `skills` list is
            appended automatically with the default agent-skill discovery paths
            plus anything in `extraSkillPaths`.
          '';
        };

        extraSkillPaths = mkOption {
          type = listOf str;
          default = [ ];
          description = "Additional skill directory paths appended to the default discovery list.";
        };

        skills = mkOption {
          type = attrsOf (
            submodule (
              { name, ... }: {
                options = {
                  enable = mkOption {
                    type = bool;
                    default = true;
                    description = "Whether to install the ${name} Pi skill.";
                  };

                  package = mkOption {
                    type = package;
                    default = pkgs.pi-skills.${name};
                    defaultText = "pkgs.pi-skills.${name}";
                    description = "Package providing the ${name} Pi skill.";
                  };
                };
              }
            )
          );
          default = defaultSkills;
          description = "Pi skills to expose under `~/.agents/skills`.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        xdg.configFile."pi/agent/settings.json".text = builtins.toJSON (
          cfg.settings
          // {
            skills = unique (
              [
                "${config.xdg.configHome}/codex/skills"
                "${config.home.homeDirectory}/.claude/skills"
                "${config.home.homeDirectory}/.agents/skills"
              ]
              ++ cfg.extraSkillPaths
            );
          }
        );

        home.file = mapAttrs' (name: skill: nameValuePair ".agents/skills/${name}" { source = skill.package; }) (
          filterAttrs (_name: skill: skill.enable) cfg.skills
        );
      };
    };
}
