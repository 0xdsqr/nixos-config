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
    settings = lib.recursiveUpdate (lib.recursiveUpdate hermesShared.providers hermesShared.cognition) {
      inherit (hermesShared) display model;
      agent.reasoning_effort = "medium";
      discord.server_actions = [
        "search_members"
        "fetch_messages"
        "create_thread"
      ];
      discord.gateway_restart_notification = false;
      gateway.platforms.a2a.enabled = false;
      platform_toolsets = {
        discord = hermesShared.commonToolsets ++ [ "discord" ];
      };
      inherit (hermesShared) skills;
      terminal.cwd = "/var/lib/hermes/.hermes/profiles/vanilla/workspace";
      tts.elevenlabs.voice_id = "21m00Tcm4TlvDq8ikWAM";
    };
    environment = {
      DISCORD_ALLOWED_USERS = hermesShared.allowedUsers;
      DISCORD_ALLOWED_CHANNELS = "1465807038587076700";
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1465807038587076700";
      DISCORD_HOME_CHANNEL = "1465807038587076700";
      DISCORD_REQUIRE_MENTION = "false";
    };
  };
}
