{
  inputs,
  ...
}:
{
  imports = [
    # Import dsqr-nix darwin module
    (inputs.self.darwinModules.dsqr-nix inputs)
  ];
  # Basic system settings
  system.stateVersion = 5;
  ids.gids.nixbld = 350; # For Determinate Nix installer

  # Let Determinate manage the Nix installation on macOS.
  nix.enable = false;

  # Configure eevee module
  eevee = (import ../users/eevee-defaults.nix) // {
    darwin.exclude_casks = [ ]; # Add casks to exclude if needed
  };
}
