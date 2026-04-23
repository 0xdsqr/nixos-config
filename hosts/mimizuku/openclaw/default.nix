{ config, nix-openclaw, ... }:
let
  cloudflareAccountId = "f8913f78ee578f0e62ccb9ad8a89c60f";
  cloudflareGatewayId = "mimizuku";
in
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

      home.file.".openclaw/openclaw.json".force = true;

      programs.openclaw = {
        documents = ./documents/noctua;

        instances.default = {
          enable = true;
          stateDir = "/home/dsqr/.openclaw";
          workspaceDir = "/home/dsqr/.openclaw/workspace";

          config = {
            agents.defaults = {
              model = {
                primary = "cloudflare-workers-ai/@cf/moonshotai/kimi-k2.6";
                fallbacks = [ "cloudflare-workers-ai/@cf/meta/llama-3.3-70b-instruct-fp8-fast" ];
              };
            };

            models = {
              mode = "merge";
              providers.cloudflare-workers-ai = {
                api = "openai-completions";
                baseUrl = "https://gateway.ai.cloudflare.com/v1/${cloudflareAccountId}/${cloudflareGatewayId}/workers-ai/v1";
                apiKey = {
                  source = "env";
                  provider = "cloudflare-workers-ai";
                  id = "CLOUDFLARE_API_TOKEN";
                };
                models = [
                  {
                    id = "@cf/moonshotai/kimi-k2.6";
                    name = "Kimi K2.6 via Cloudflare Workers AI";
                    reasoning = true;
                    input = [
                      "text"
                      "image"
                    ];
                    contextWindow = 262144;
                    maxTokens = 32768;
                    compat.maxTokensField = "max_completion_tokens";
                  }
                  {
                    id = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
                    name = "Llama 3.3 70B Fast via Cloudflare Workers AI";
                    input = [ "text" ];
                    compat.maxTokensField = "max_completion_tokens";
                  }
                ];
              };
            };

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
