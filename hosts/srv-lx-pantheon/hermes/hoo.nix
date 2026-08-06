{
  config,
  hermesShared,
  lib,
  ...
}:
{
  age.secrets.hermes-hoo-environment = {
    file = ../hermes-hoo.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0440";
  };

  services.hermes-agent = {
    enable = true;
    inherit (hermesShared) package;

    addToSystemPackages = true;
    environmentFiles = [
      hermesShared.providersEnvironmentFile
      config.age.secrets.hermes-hoo-environment.path
    ];
    settings = lib.recursiveUpdate (lib.recursiveUpdate hermesShared.providers hermesShared.cognition) {
      inherit (hermesShared) display model;
      agent.reasoning_effort = "high";
      a2a_agents.vanilla = {
        url = "http://127.0.0.1:9901";
        timeout = 120;
        capabilities = [
          "conversation"
          "memory"
        ];
      };
      discord.server_actions = [
        "list_guilds"
        "server_info"
        "list_channels"
        "channel_info"
        "list_roles"
        "member_info"
        "search_members"
        "fetch_messages"
        "list_pins"
        "pin_message"
        "unpin_message"
        "delete_message"
        "create_thread"
        "add_role"
        "remove_role"
      ];
      gateway.platforms.a2a = {
        enabled = true;
        extra.port = 9900;
      };
      platform_toolsets = {
        a2a = hermesShared.commonToolsets;
        discord = hermesShared.commonToolsets ++ [
          "discord"
          "discord_admin"
        ];
      };
      skills = hermesShared.curateSkills hermesShared.enabledSkills;
      tts.elevenlabs.voice_id = "pNInz6obpgDQGcFmaJgB";
    };
    environment = {
      A2A_AGENT_NAME = "hoo";
      DISCORD_ALLOWED_USERS = hermesShared.allowedUsers;
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1496697794285539348";
      DISCORD_REQUIRE_MENTION = "true";
    };
  };

  systemd.services.hermes-agent = {
    environment.LD_LIBRARY_PATH = hermesShared.opusLibraryPath;
    serviceConfig = hermesShared.resources;
  };
}
