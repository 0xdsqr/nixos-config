{ config, hermesShared, ... }: {
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
    environmentFiles = [ config.age.secrets.hermes-hoo-environment.path ];
    settings = { inherit (hermesShared) display model; };
    environment = {
      DISCORD_ALLOWED_USERS = hermesShared.allowedUsers;
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1496697794285539348";
      DISCORD_REQUIRE_MENTION = "true";
    };
  };

  systemd.services.hermes-agent.serviceConfig = hermesShared.resources;
}
