{
  inputs,
  config,
  pkgs,
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

  # Nix configuration
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-users = [ "@admin" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Configure eevee module
  eevee = {
    full_name = "0xdsqr";
    email_address = "dave.dennis@gs.com";
    theme = "tokyo-night";
    darwin.exclude_casks = [ ]; # Add casks to exclude if needed
  };
}
