{ dtil, ... }:
{
  imports = dtil.modules.collectNix {
    dir = ./.;
    ignoredFiles = [
      ./default.nix
      ./meta.nix
    ];
  };

  system.stateVersion = 5;
  ids.gids.nixbld = 350;

  # Let Determinate manage the Nix installation on macOS.
  nix.enable = false;

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is.
  users.users.dsqr.home = "/Users/dsqr";

  system.primaryUser = "dsqr";
  dsqr.darwin.devbox.enable = true;
}
