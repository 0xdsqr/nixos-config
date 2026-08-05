_: {
  # Intentionally disabled until the Discord bots, channel policy, and agenix
  # environment files have been created. Each instance runs with isolated
  # memory, sessions, OAuth state, and resource limits.
  dsqr.nixos.hermes = {
    enable = false;

    instances = {
      hoo = { };
      vanalia = { };
    };
  };
}
