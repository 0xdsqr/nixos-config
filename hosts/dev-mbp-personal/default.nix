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
    attrValues commonModules ++ attrValues darwinModules ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);
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
      { ... }:
      {
        imports = modules;

        dsqr.darwin = {
          determinate.enable = true;
          hostname.smb.enable = true;

          desktop = {
            dock.enable = true;
            system.enable = true;
            windowManager.enable = true;
            maccy.enable = true;
            codex.enable = true;
            hammerspoon.enable = true;
            obs-studio.enable = true;
            communication.discord.enable = true;
          };
        };

        allowedUnfreePackageNames = [
          "claude-code"
          "google-chrome"
          "opencode"
        ];

        home-manager.users.dsqr.dsqr.home = {
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
