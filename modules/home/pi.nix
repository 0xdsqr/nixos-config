{
  flake.homeModules.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf package str;

      cfg = config.dsqr.home.pi;
    in
    {
      options.dsqr.home.pi = {
        enable = mkEnableOption "Pi coding agent" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs."pi-coding-agent";
          description = "Pi coding agent package to install.";
        };

        extraSkills = mkOption {
          type = listOf str;
          default = [ ];
          description = "Additional skill paths appended to the default Pi agent skills list.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        xdg.configFile."pi/agent/settings.json" = {
          text = builtins.toJSON {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.4";
            defaultThinkingLevel = "high";
            skills = [
              "${config.xdg.configHome}/codex/skills"
              "~/.claude/skills"
            ]
            ++ cfg.extraSkills;
          };
        };
      };
    };
}
