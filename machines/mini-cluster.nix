{
  inputs,
  currentSystemName,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.dsqr-mini-cluster
  ];

  # Use the flake config name as the hostname (e.g., dsqr-mini-001).
  networking.hostName = currentSystemName;

  system.stateVersion = 5;
}
