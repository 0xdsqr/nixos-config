{
  config,
  inputs,
  pkgs,
  ...
}:
let
  allowedUsers = "618575437995442197,980636531565949019";
  model = {
    default = "gpt-5.6-sol";
    provider = "openai-codex";
  };
  package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;
in
{
  age.secrets = {
    hermes-hoo-environment = {
      file = ./hermes-hoo.env.age;
      owner = "hermes";
      group = "hermes";
      mode = "0440";
    };

    hermes-vanalia-environment = {
      file = ./hermes-vanalia.env.age;
      owner = "hermes";
      group = "hermes";
      mode = "0440";
    };
  };

  services.hermes-agent = {
    enable = true;
    inherit package;

    addToSystemPackages = true;
    environmentFiles = [ config.age.secrets.hermes-hoo-environment.path ];
    settings.model = model;
    environment = {
      DISCORD_ALLOWED_USERS = allowedUsers;
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1496697794285539348";
      DISCORD_REQUIRE_MENTION = "true";
    };
  };

  dsqr.nixos.hermes.profiles.vanalia = {
    environmentFiles = [ config.age.secrets.hermes-vanalia-environment.path ];
    settings = {
      inherit model;
      terminal.cwd = "/var/lib/hermes/.hermes/profiles/vanalia/workspace";
    };
    environment = {
      DISCORD_ALLOWED_USERS = allowedUsers;
      DISCORD_ALLOWED_CHANNELS = "1465807038587076700";
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1465807038587076700";
      DISCORD_HOME_CHANNEL = "1465807038587076700";
      DISCORD_REQUIRE_MENTION = "false";
    };
  };

  systemd.services = {
    hermes-agent.serviceConfig = {
      CPUQuota = "150%";
      MemoryHigh = "1536M";
      MemoryMax = "2G";
      TasksMax = 512;
    };

    hermes-agent-vanalia.serviceConfig = {
      CPUQuota = "150%";
      MemoryHigh = "1536M";
      MemoryMax = "2G";
      TasksMax = 512;
    };
  };
}
