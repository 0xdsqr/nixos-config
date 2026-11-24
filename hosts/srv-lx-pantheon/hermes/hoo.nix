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
      hermesShared.xmcpEnvironmentFile
      config.age.secrets.hermes-hoo-environment.path
    ];
    settings = lib.recursiveUpdate (lib.recursiveUpdate hermesShared.providers hermesShared.cognition) {
      inherit (hermesShared) display model;
      mcp_servers = hermesShared.mcpServers;
      agent.reasoning_effort = "high";
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
      # Settings merge into the on-disk config.yaml, so the retired A2A
      # listener has to be switched off explicitly rather than just omitted.
      gateway.platforms.a2a.enabled = false;
      platform_toolsets = {
        discord = hermesShared.commonToolsets ++ [
          "discord"
          "discord_admin"
          "mcp-xapi"
          "mcp-xdocs"
        ];
      };
      inherit (hermesShared) skills;
      tts.elevenlabs.voice_id = "pNInz6obpgDQGcFmaJgB";
    };
    environment = {
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
