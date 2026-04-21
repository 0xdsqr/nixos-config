{ config, nix-openclaw, ... }:
{
  age.secrets.openclawGatewayAuthToken = {
    file = ./gateway.auth-token.age;
    path = "/run/agenix/openclaw-gateway-auth-token";
    owner = "dsqr";
    mode = "0400";
  };

  age.secrets.openclawOpenAIApiKey = {
    file = ./openai.api-key.age;
    path = "/run/agenix/openclaw-openai-api-key";
    owner = "dsqr";
    mode = "0400";
  };

  home-manager.users.dsqr = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    programs.openclaw = {
      enable = true;

      config = {
        secrets = {
          providers = {
            default = {
              source = "env";
            };
            gatewayauth = {
              source = "file";
              inherit (config.age.secrets.openclawGatewayAuthToken) path;
              mode = "singleValue";
            };
            openaiapikey = {
              source = "file";
              inherit (config.age.secrets.openclawOpenAIApiKey) path;
              mode = "singleValue";
            };
          };
          defaults = {
            env = "default";
            file = "gatewayauth";
          };
        };

        agents.defaults.model.primary = "openai-codex/gpt-5.4";

        models.providers.openai.apiKey = {
          source = "file";
          provider = "openaiapikey";
          id = "value";
        };

        gateway = {
          mode = "local";
          auth = {
            mode = "token";
            token = {
              source = "file";
              provider = "gatewayauth";
              id = "value";
            };
          };
        };
      };
    };
  };
}
