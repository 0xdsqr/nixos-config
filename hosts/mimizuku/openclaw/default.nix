{
  config,
  inputs,
  lib,
  ...
}:
let
  openclawEnvAgeFile = ./openclaw.env.age;
  secretsReady = builtins.pathExists openclawEnvAgeFile;
in
{
  users.users.dsqr.linger = true;

  # Keep the gateway private by default while still leaving room for a future
  # Tailscale-backed macOS node bridge.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 18789 ];

  age.secrets = lib.mkIf secretsReady {
    openclawEnv = {
      file = openclawEnvAgeFile;
      path = "/run/agenix/openclaw.env";
      owner = "dsqr";
      mode = "0400";
    };
  };

  home-manager.users.dsqr = lib.mkIf secretsReady {
    imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

    home.file = {
      ".openclaw/workspace-vanalia/AGENTS.md".source = ./documents/vanalia/AGENTS.md;
      ".openclaw/workspace-vanalia/SOUL.md".source = ./documents/vanalia/SOUL.md;
      ".openclaw/workspace-vanalia/TOOLS.md".source = ./documents/vanalia/TOOLS.md;
    };

    programs.openclaw = {
      enable = true;
      documents = ./documents/noctua;
      workspaceDir = "~/.openclaw/workspace-noctua";

      bundledPlugins = {
        summarize.enable = true;
        goplaces.enable = false;
      };

      config = {
        secrets = {
          providers.default = {
            source = "env";
          };

          defaults.env = "default";
        };

        gateway = {
          mode = "local";
          auth = {
            mode = "token";
            token = {
              id = "OPENCLAW_GATEWAY_TOKEN";
              provider = "default";
              source = "env";
            };
          };
        };

        channels.discord = {
          enabled = true;
          dmPolicy = "pairing";
          groupPolicy = "allowlist";

          accounts = {
            noctua = {
              token = {
                id = "TOKEN_NOCTUA";
                provider = "default";
                source = "env";
              };
            };

            vanalia = {
              token = {
                id = "TOKEN_VANALIA";
                provider = "default";
                source = "env";
              };
            };
          };
        };

        agents = {
          defaults = {
            # OpenClaw's current OpenAI OAuth path is Codex-oriented and maps to
            # `openai-codex/gpt-5.4`. For a documented GPT-4-class OAuth/device-login
            # path, GitHub Copilot's built-in provider currently exposes `gpt-4o`.
            model = {
              primary = "github-copilot/gpt-4o";
            };
          };

          list = [
            {
              id = "noctua";
              name = "Noctua";
              default = true;
              workspace = "~/.openclaw/workspace-noctua";
              agentDir = "~/.openclaw/agents/noctua/agent";
              groupChat.mentionPatterns = [ "noctua" ];
            }
            {
              id = "vanalia";
              name = "Vanalia";
              workspace = "~/.openclaw/workspace-vanalia";
              agentDir = "~/.openclaw/agents/vanalia/agent";
              groupChat.mentionPatterns = [ "vanalia" ];
            }
          ];
        };

        bindings = [
          {
            agentId = "noctua";
            match = {
              channel = "discord";
              accountId = "noctua";
            };
          }
          {
            agentId = "vanalia";
            match = {
              channel = "discord";
              accountId = "vanalia";
            };
          }
        ];
      };
    };

    systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [ config.age.secrets.openclawEnv.path ];
  };

  warnings = lib.optionals (!secretsReady) [
    ''
      OpenClaw on mimizuku is scaffolded but disabled until this file exists:
      - hosts/mimizuku/openclaw/openclaw.env.age
    ''
  ];
}
