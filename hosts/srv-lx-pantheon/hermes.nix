_: {
  # Intentionally disabled until the Discord bots, channel policy, and agenix
  # environment files have been created. Each instance runs with isolated
  # memory, sessions, OAuth state, and resource limits.
  dsqr.nixos.hermes = {
    enable = true;

    instances = {
      hoo = {
        environmentAgeFile = ./hermes-hoo.env.age;
        allowedUsers = [
          "618575437995442197"
          "980636531565949019"
        ];
      };

      vanalia = {
        environmentAgeFile = ./hermes-vanalia.env.age;
        allowedUsers = [
          "618575437995442197"
          "980636531565949019"
        ];
        allowedChannels = [ "1465807038587076700" ];
        freeResponseChannels = [ "1465807038587076700" ];
        homeChannel = "1465807038587076700";
        requireMention = false;
      };
    };
  };
}
