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

  # Configure dsqr-nix module
  dsqrDevbox = {
    full_name = "0xdsqr";
    email_address = "dave.dennis@gs.com";
    theme = "tokyo-night";
  };
}
