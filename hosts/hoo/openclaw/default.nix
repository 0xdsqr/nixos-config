{ config, nix-openclaw, ... }:
let
  cloudflareAccountId = "f8913f78ee578f0e62ccb9ad8a89c60f";
  # Keep the existing Cloudflare AI Gateway identifier stable even though the
  # host directory is now named "hoo".
  cloudflareGatewayId = "mimizuku";
  openclawEnvFile = config.age.secrets.openclawEnv.path;
  pluginDefs = import ./plugins.nix;
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
    (
      { ... }:
      {
        imports = [
          (_: { _module.args = { inherit openclawEnvFile pluginDefs; }; })
          ./hoo.nix
          ./vanilla.nix
        ];

        programs.openclaw = {
          # Avoid user profile PATH collisions when plugin binaries overlap with
          # tools that the base OpenClaw package already exposes.
          exposePluginPackages = false;

          # We want different persona docs per instance, so we do not use the
          # current global `programs.openclaw.documents` option here.
          documents = null;
          inherit (pluginDefs) bundledPlugins;

          config = {
            agents.defaults.model = {
              primary = "cloudflare-workers-ai/@cf/moonshotai/kimi-k2.6";
              fallbacks = [ "cloudflare-workers-ai/@cf/meta/llama-3.3-70b-instruct-fp8-fast" ];
            };

            models = {
              mode = "merge";
              providers.cloudflare-workers-ai = {
                api = "openai-completions";
                baseUrl = "https://gateway.ai.cloudflare.com/v1/${cloudflareAccountId}/${cloudflareGatewayId}/workers-ai/v1";
                apiKey = "\${CLOUDFLARE_API_TOKEN}";
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
      }
    )
  ];
}
