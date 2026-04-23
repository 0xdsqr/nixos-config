{
  flake.darwinModules.ollama =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      inherit (config.dsqr.darwin) exo;
    in
    mkIf exo.enable { homebrew.casks = [ "ollama" ]; };
}
