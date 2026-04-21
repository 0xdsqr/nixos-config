{ config, nix-openclaw, ... }:
{
  age.secrets.openclawEnv = {
    file = ./openclaw.env.age;
    path = "/run/agenix/openclaw-env";
    owner = "dsqr";
    mode = "0400";
  };

  home-manager.users.dsqr = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [
      config.age.secrets.openclawEnv.path
    ];

    programs.openclaw = {
      instances.default = {
        enable = true;
        stateDir = "~/.openclaw";
        workspaceDir = "~/.openclaw/workspace";

        config = {
          agents.defaults.model.primary = "openai-codex/gpt-5.4";

          models.providers.openai.apiKey = "\${OPENAI_API_KEY}";

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
