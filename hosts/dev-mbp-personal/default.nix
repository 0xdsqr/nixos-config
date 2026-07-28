{ self, ... }:
let
  inherit (self.lib)
    commonModules
    darwinModules
    homeModules
    nixLib
    ;
  inherit (nixLib.attrsets) attrValues;
  inherit (nixLib.lists) singleton;

  hostName = "dev-mbp-personal";

  modules =
    attrValues commonModules
    ++ attrValues darwinModules
    ++ [
      ../../profiles/dsqr/common.nix
      ../../profiles/dsqr/darwin.nix
      ../../profiles/observability/darwin.nix
    ]
    ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "darwin";
    path = ./.;
    sshHost = "10.10.20.126";
    system = "aarch64-darwin";
  };

  flake.darwinConfigurations.${hostName} = self.lib.darwinSystem {
    inherit hostName;

    modules = singleton (
      { ... }: {
        imports = modules;

        dsqr.darwin = {
          determinate.enable = true;
          grafana.alloy.enable = false;
          hostname.smb.enable = true;
          security.certificates.homeRootCA.systemKeychain.enable = true;

          desktop = {
            dock.enable = true;
            fileExplorer.enable = true;
            hygiene.enable = true;
            system.enable = true;
            windowManager.enable = true;
            maccy.enable = true;
            hammerspoon.enable = true;
            obs-studio.enable = true;
            statusClock.enable = true;
            communication.discord.enable = true;
          };
        };

        allowedUnfreePackageNames = [
          "claude-code"
          "google-chrome"
          "opencode"
        ];

        home-manager.users.dsqr = {
          programs.pi = {
            enable = true;
            models.providers.exo = {
              baseUrl = "https://exo.service.home.arpa/v1";
              api = "openai-completions";
              apiKey = "!security find-generic-password -w -a dsqr -s exo.home.arpa";
              authHeader = false;
              headers.Authorization = "!password=\"$(security find-generic-password -w -a dsqr -s exo.home.arpa)\"; printf 'Basic %s' \"$(printf 'dsqr:%s' \"$password\" | base64)\"";
              compat = {
                supportsDeveloperRole = false;
                supportsReasoningEffort = false;
                thinkingFormat = "qwen";
              };
              models = [
                {
                  id = "mlx-community/Qwen3.5-122B-A10B-6bit";
                  name = "Qwen3.5 122B A10B 6-bit (Exo)";
                  input = [
                    "text"
                    "image"
                  ];
                  reasoning = true;
                  contextWindow = 262144;
                }
              ];
            };
            themes.dsqr-midnight.enable = true;
          };

          dsqr.home = {
            agentSkills = {
              git-workflow.targets = [ "claude" ];
              i-have-adhd.targets = [
                "agents"
                "claude"
              ];
            };

            aws.config = {
              enable = true;
              sections = {
                "profile dsqr-dave" = {
                  sso_session = "dsqr";
                  sso_account_id = "244826541288";
                  sso_role_name = "AdministratorAccess";
                  region = "us-east-1";
                  output = "json";
                };

                "sso-session dsqr" = {
                  sso_start_url = "https://d-90660ae665.awsapps.com/start";
                  sso_region = "us-east-1";
                  sso_registration_scopes = "sso:account:access";
                };
              };
            };

            desktop = {
              browsers.googleChrome.enable = true;
              codexbar.enable = true;
              hammerspoon.enable = true;
              windowManager.enable = true;
            };

            ssh.extraConfig = /* sshconfig */ ''
              Host github.com
                HostName github.com
                User git
                IdentityFile ~/.ssh/github_automation
                IdentitiesOnly yes
            '';
          };
        };

        networking = {
          inherit hostName;
          computerName = hostName;
          localHostName = hostName;
        };

        system.stateVersion = 5;
      }
    );
  };
}
