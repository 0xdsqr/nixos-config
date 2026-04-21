{ config, nix-openclaw, ... }:
{
  age.secrets.openclawEnv = {
    file = ./openclaw.env.age;
    owner = "dsqr";
    mode = "0400";
  };

  home-manager.backupFileExtension = "hm-backup";

  home-manager.users.dsqr = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [ config.age.secrets.openclawEnv.path ];

    programs.openclaw = {
      instances.default = {
        enable = true;
        stateDir = "/home/dsqr/.openclaw";
        workspaceDir = "/home/dsqr/.openclaw/workspace";

        config = {
          agents.defaults.model.primary = "openai-codex/gpt-5.4";

          models.providers.openai = {
            baseUrl = "https://api.openai.com/v1";
            apiKey = "\${OPENAI_API_KEY}";
          };

          channels.discord = {
            token = "\${DISCORD_NOCTUA_TOKEN}";
            allowFrom = [ "618575437995442197" ];
            groupPolicy = "allowlist";
            guilds."1465602840713101598" = {
              requireMention = true;
              users = [ "618575437995442197" ];
            };
          };

          gateway = {
            mode = "local";
            auth = {
              mode = "token";
              token = "\${OPENCLAW_GATEWAY_TOKEN}";
            };
          };
        };
      };
    };
  };
}
