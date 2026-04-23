{ config, lib, nix-openclaw, ... }:
let
  openclawEnvFile = config.age.secrets.openclawEnv.path;
  cloudflareAccountId = "f8913f78ee578f0e62ccb9ad8a89c60f";
  # Keep the existing Cloudflare AI Gateway identifier stable even though the
  # host directory is now named "hoo".
  cloudflareGatewayId = "mimizuku";
  legacyReferenceDir = "/home/dsqr/vanilla-legacy";
  baseWorkspaceDocNames = [
    "AGENTS.md"
    "SOUL.md"
    "TOOLS.md"
  ];
  optionalWorkspaceDocNames = [
    "IDENTITY.md"
    "USER.md"
    "LORE.md"
    "HEARTBEAT.md"
    "PROMPTING-EXAMPLES.md"
    "MEMORY.md"
    "BOOTSTRAP.md"
  ];
  mkWorkspaceDocsActivation =
    {
      workspaceDir,
      docDir,
      extraDocNames ? [ ],
    }:
    let
      docNames = builtins.filter (docName: builtins.pathExists (docDir + "/${docName}")) (
        baseWorkspaceDocNames ++ optionalWorkspaceDocNames ++ extraDocNames
      );
      seedCommands = builtins.concatStringsSep "\n" (
        map (docName: ''
          target="$HOME/${workspaceDir}/${docName}"
          if [ ! -e "$target" ] || [ -L "$target" ]; then
            rm -f "$target"
            mkdir -p "$(dirname "$target")"
            cp ${docDir + "/${docName}"} "$target"
            chmod u+rw "$target"
          fi
        '') docNames
      );
    in
    ''
      ${seedCommands}
    '';
  commonInstanceConfig = {
    agents.defaults.model = {
      primary = "openai/gpt-5.4";
      fallbacks = [ ];
    };

    # `imageModel` is the multimodal "look at this image" fallback that some
    # OpenClaw paths and CLI surfaces use. `imageGenerationModel` is the
    # dedicated "make/edit an image" model chain.
    agents.defaults.imageModel = {
      primary = "openai/gpt-5.4";
      fallbacks = [ ];
    };

    agents.defaults.imageGenerationModel = {
      primary = "google/nano-banana";
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
  };
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
    ({ config, lib, ... }: {
      programs.openclaw = {
        # Avoid user profile PATH collisions when plugin binaries overlap with
        # tools that the base OpenClaw package already exposes.
        exposePluginPackages = false;

        # We want different persona docs per instance, so we do not use the
        # current global `programs.openclaw.documents` option here.
        documents = null;
        bundledPlugins = { };

        instances.hoo = {
          enable = true;
          gatewayPort = 18789;

          config = lib.recursiveUpdate commonInstanceConfig {
            channels.discord = {
              enabled = true;
              token = "\${DISCORD_HOO_TOKEN}";
              allowFrom = [ "618575437995442197" ];
              groupPolicy = "allowlist";
              guilds."1465602840713101598" = {
                requireMention = true;
                users = [ "618575437995442197" ];
                channels = {
                  "*" = {
                    enabled = false;
                    requireMention = true;
                  };
                  "1496697794285539348" = {
                    enabled = true;
                    requireMention = false;
                  };
                };
              };
            };
          };
        };

        instances.vanilla = {
          enable = true;
          gatewayPort = 18790;

          config = lib.recursiveUpdate commonInstanceConfig {
            channels.discord = {
              enabled = true;
              token = "\${DISCORD_VANILLA_TOKEN}";
              allowFrom = [
                "618575437995442197"
                "980636531565949019"
              ];
              groupPolicy = "allowlist";
              guilds."1465602840713101598" = {
                requireMention = true;
                users = [
                  "618575437995442197"
                  "980636531565949019"
                ];
                channels = {
                  "*" = {
                    enabled = false;
                    requireMention = true;
                  };
                  "1465807038587076700" = {
                    enabled = true;
                    requireMention = false;
                  };
                };
              };
            };
          };
        };
      };

      systemd.user.services.openclaw-gateway-hoo = lib.mkIf (config.programs.openclaw.instances.hoo.enable or false) {
        Unit = {
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service.EnvironmentFile = [ openclawEnvFile ];
      };

      systemd.user.services.openclaw-gateway-vanilla =
        lib.mkIf (config.programs.openclaw.instances.vanilla.enable or false)
          {
            Unit = {
              After = [ "network-online.target" ];
              Wants = [ "network-online.target" ];
            };

            Install = {
              WantedBy = [ "default.target" ];
            };

            Service.EnvironmentFile = [ openclawEnvFile ];
          };

      home.file = {
        ".openclaw-hoo/openclaw.json".force = true;
        ".openclaw-vanilla/openclaw.json".force = true;
        ".openclaw-vanilla/workspace/reference/legacy" = {
          source = config.lib.file.mkOutOfStoreSymlink legacyReferenceDir;
          force = true;
        };
      };

      home.activation = {
        openclaw-hoo-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
          workspaceDir = ".openclaw-hoo/workspace";
          docDir = ./documents/noctua;
        });
        openclaw-vanilla-workspace-docs = lib.hm.dag.entryAfter [ "linkGeneration" ] (mkWorkspaceDocsActivation {
          workspaceDir = ".openclaw-vanilla/workspace";
          docDir = ./documents/vanilla;
        });
      };
    })
  ];
}
