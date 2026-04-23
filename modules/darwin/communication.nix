{
  flake.darwinModules.communication =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      inherit (config.dsqr.darwin) devbox;
    in
    mkIf devbox.enable {
      homebrew.casks = [
        "discord"
        "signal"
        "slack"
        "zoom"
      ];
    };
}
