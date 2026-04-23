{
  config,
  lib,
  openclawEnvFile,
  pluginDefs,
  ...
}:
let
  workspaceDir = ".openclaw-hoo/workspace";
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
  programs.openclaw.instances.hoo = {
    enable = true;
    gatewayPort = 18789;
    plugins = pluginDefs.hooPlugins;

    config.channels.discord = {
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

  home.file = {
    ".openclaw-hoo/openclaw.json".force = true;
  }
  // (mkWorkspaceDocs ./documents/noctua);
}
