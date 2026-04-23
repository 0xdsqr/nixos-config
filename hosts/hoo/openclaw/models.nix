let
  cloudflareAccountId = "f8913f78ee578f0e62ccb9ad8a89c60f";
  # Keep the existing Cloudflare AI Gateway identifier stable even though the
  # host directory is now named "hoo".
  cloudflareGatewayId = "mimizuku";
in
{
  agents.defaults.model = {
    primary = "openai/gpt-5.4";
    fallbacks = [ ];
  };

  agents.defaults.imageGenerationModel = {
    primary = "google/gemini-3.1-flash-image-preview";
    fallbacks = [ "openai/gpt-image-1" ];
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

  plugins.entries = {
    brave = {
      enabled = true;
      config.webSearch = {
        apiKey = "\${BRAVE_API_KEY}";
        mode = "web";
      };
    };
    openai.enabled = true;
  };

  tools.web.search = {
    enabled = true;
    provider = "brave";
    maxResults = 5;
    timeoutSeconds = 30;
  };

}
