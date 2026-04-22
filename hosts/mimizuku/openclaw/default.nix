{ config, nix-openclaw, ... }:
{
  age.secrets.openclawEnv = {
    file = ./openclaw.env.age;
    owner = "dsqr";
    mode = "0400";
  };

  users.users.dsqr.linger = true;

  dsqr.home.imports = [
    nix-openclaw.homeManagerModules.openclaw
    {
      systemd.user.services.openclaw-gateway = {
        Unit = {
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service.EnvironmentFile = [ config.age.secrets.openclawEnv.path ];
      };

      programs.openclaw = {
        documents = ./documents/noctua;

        instances.default = {
          enable = true;
          stateDir = "/home/dsqr/.openclaw";
          workspaceDir = "/home/dsqr/.openclaw/workspace";

          config = {
            agents.defaults.model.primary = "openai/gpt-5.4";

            channels.discord = {
              enabled = true;
              token = "\${DISCORD_NOCTUA_TOKEN}";
              allowFrom = [ "618575437995442197" ];
              groupPolicy = "allowlist";
              guilds."1465602840713101598" = {
                requireMention = true;
                users = [ "618575437995442197" ];
                channels = {
                  "*" = {
                    enabled = true;
                    requireMention = true;
                  };
                  "1495956898481049672" = {
                    enabled = true;
                    requireMention = false;
                  };
                };
              };
            };

            gateway = {
              mode = "local";
              auth = {
                mode = "token";
                token = "\${OPENCLAW_GATEWAY_TOKEN}";
              };
            };

            plugins.entries.openai.enabled = true;
          };
        };
      };
    }
  ];
}
