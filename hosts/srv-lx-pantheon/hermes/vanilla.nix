{ config, hermesShared, ... }: {
  age.secrets.hermes-vanilla-environment = {
    file = ../hermes-vanilla.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0440";
  };

  dsqr.nixos.hermes.profiles.vanilla = {
    environmentFiles = [ config.age.secrets.hermes-vanilla-environment.path ];
    settings = {
      inherit (hermesShared) display model;
      terminal.cwd = "/var/lib/hermes/.hermes/profiles/vanilla/workspace";
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

  systemd.services.hermes-agent-vanilla.serviceConfig = hermesShared.resources;
}
