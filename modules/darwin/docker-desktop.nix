{
  flake.darwinModules."docker-desktop" =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      inherit (config.dsqr.darwin) devbox;
    in
    mkIf devbox.enable { homebrew.casks = [ "docker-desktop" ]; };
}
