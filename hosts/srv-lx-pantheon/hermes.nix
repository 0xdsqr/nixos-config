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
  display = {
    interim_assistant_messages = false;
    show_commentary = false;
    show_reasoning = false;
    tool_progress = "off";
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

    hermes-vanilla-environment = {
      file = ./hermes-vanilla.env.age;
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
    settings = { inherit display model; };
    environment = {
      DISCORD_ALLOWED_USERS = allowedUsers;
      DISCORD_ALLOW_BOTS = "none";
      DISCORD_FREE_RESPONSE_CHANNELS = "1496697794285539348";
      DISCORD_REQUIRE_MENTION = "true";
    };
  };

  dsqr.nixos.hermes.profiles.vanilla = {
    environmentFiles = [ config.age.secrets.hermes-vanilla-environment.path ];
    settings = {
      inherit display model;
      terminal.cwd = "/var/lib/hermes/.hermes/profiles/vanilla/workspace";
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

    hermes-agent-vanilla.serviceConfig = {
      CPUQuota = "150%";
      MemoryHigh = "1536M";
      MemoryMax = "2G";
      TasksMax = 512;
    };
  };
}
