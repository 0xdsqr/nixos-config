{
  inputs,
  currentSystemName,
  ...
}:
{
  imports = [
    (inputs.self.darwinModules.dsqr-nix inputs)
    inputs.self.darwinModules.dsqr-mini-cluster
  ];

  # Use the flake config name as the hostname (e.g., dsqr-mini-001).
  networking.hostName = currentSystemName;

  # Cluster nodes should share the same eevee defaults.
  eevee = import ../users/eevee-defaults.nix;

  system.stateVersion = 5;
}
