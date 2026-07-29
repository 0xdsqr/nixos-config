{
  flake.homeModules.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrByPath optionalAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.codex;
      herdrCfg = attrByPath [ "dsqr" "home" "desktop" "ghostty" "herdr" ] {
        enable = false;
        integrations = {
          codex.enable = false;
          artifacts = null;
        };
      } config;
      herdrIntegrationEnabled =
        herdrCfg.enable && herdrCfg.integrations.codex.enable && herdrCfg.integrations.artifacts != null;
      herdrHook = "${config.xdg.configHome}/codex/herdr-agent-state.sh";
    in
    {
      options.dsqr.home.codex = {
        enable = mkEnableOption "Codex CLI tooling and config" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.codex;
          description = "Codex package to install.";
        };
      };

      config = mkIf cfg.enable {
        programs.codex = {
          enable = true;
          inherit (cfg) package;
          settings.features = {
            child_agents_md = true;
          }
          // optionalAttrs herdrIntegrationEnabled { hooks = true; };
        };

        xdg.configFile = {
          "codex/plugins/README.md" = {
            text = "Drop Codex plugins here when you want them managed declaratively.\n";
          };

          "codex/agents/README.md" = {
            text = "Drop Codex agent presets here when you want them managed declaratively.\n";
          };
        }
        // optionalAttrs herdrIntegrationEnabled {
          "codex/herdr-agent-state.sh".source = "${herdrCfg.integrations.artifacts}/codex/herdr-agent-state.sh";

          "codex/hooks.json".text = builtins.toJSON {
            hooks.SessionStart = [
              {
                hooks = [
                  {
                    command = "bash '${herdrHook}' session";
                    timeout = 10;
                    type = "command";
                  }
                ];
              }
            ];
          };
        };
      };
    };
}
