{
  config,
  hermesShared,
  lib,
  ...
}:
{
  age.secrets.hermes-vanilla-environment = {
    file = ../hermes-vanilla.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0440";
  };

  dsqr.nixos.hermes.profiles.vanilla = {
    environmentFiles = [
      hermesShared.providersEnvironmentFile
      config.age.secrets.hermes-vanilla-environment.path
    ];
    settings = lib.recursiveUpdate hermesShared.providers {
      inherit (hermesShared) display model;
      a2a_agents.hoo = {
        url = "http://127.0.0.1:9900";
        timeout = 120;
        capabilities = [
          "conversation"
          "memory"
        ];
      };
      discord.server_actions = [
        "search_members"
        "fetch_messages"
        "create_thread"
      ];
      gateway.platforms.a2a = {
        enabled = true;
        extra.port = 9901;
      };
      platform_toolsets = {
        a2a = hermesShared.commonToolsets;
        discord = hermesShared.commonToolsets ++ [ "discord" ];
      };
      terminal.cwd = "/var/lib/hermes/.hermes/profiles/vanilla/workspace";
      tts.elevenlabs.voice_id = "21m00Tcm4TlvDq8ikWAM";
    };
    environment = {
      A2A_AGENT_NAME = "vanilla";
      DISCORD_ALLOWED_USERS = hermesShared.allowedUsers;
      DISCORD_ALLOWED_CHANNELS = "1465807038587076700";
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1465807038587076700";
      DISCORD_HOME_CHANNEL = "1465807038587076700";
      DISCORD_REQUIRE_MENTION = "false";
    };
  };

  systemd.services.hermes-agent-vanilla.serviceConfig = hermesShared.resources;
}
