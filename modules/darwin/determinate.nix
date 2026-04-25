{
  flake.darwinModules.determinate = {
    # Let an external Determinate Nix installation own the Nix install layer.
    nix.enable = false;
    ids.gids.nixbld = 350;
  };
}
