{ config, pkgs, ... }:
{
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
}
