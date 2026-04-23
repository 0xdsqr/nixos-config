{
  config,
  lib,
  openclawEnvFile,
  ...
}:
let
  workspaceDir = ".openclaw-vanilla/workspace";
  mkWorkspaceDocs =
    docDir:
    builtins.listToAttrs (
      map
        (name: {
          name = "${workspaceDir}/${name}";
          value = {
            source = docDir + "/${name}";
            force = true;
          };
        })
        [
          "AGENTS.md"
          "SOUL.md"
          "TOOLS.md"
        ]
    );
in
{
  programs.openclaw.instances.vanilla = {
    enable = true;
    gatewayPort = 18790;
    plugins = [ ];

    config.channels.discord = {
      enabled = true;
      token = "\${DISCORD_VANILLA_TOKEN}";
      allowFrom = [ "618575437995442197" ];
      groupPolicy = "allowlist";
      guilds."1465602840713101598" = {
        requireMention = true;
        users = [ "618575437995442197" ];
        channels."*" = {
          enabled = true;
          requireMention = true;
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
  }
  // (mkWorkspaceDocs ./documents/vanilla);
}
