{
  commonInstanceConfig,
  config,
  lib,
  mkWorkspaceDocs,
  openclawEnvFile,
  ...
}:
let
  workspaceDir = ".openclaw-vanilla/workspace";
  legacyReferenceDir = "/home/dsqr/vanilla-legacy";
in
{
  programs.openclaw.instances.vanilla = {
    enable = true;
    gatewayPort = 18790;
    plugins = [ ];

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

  systemd.user.services.openclaw-gateway-vanilla = lib.mkIf (config.programs.openclaw.instances.vanilla.enable or false) {
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
    ".openclaw-vanilla/openclaw.json".force = true;
    ".openclaw-vanilla/workspace/reference/legacy" = {
      source = config.lib.file.mkOutOfStoreSymlink legacyReferenceDir;
      force = true;
    };
  }
  // (mkWorkspaceDocs {
    inherit workspaceDir;
    docDir = ./documents/vanilla;
  });
}
