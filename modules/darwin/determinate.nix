{
  flake.darwinModules.determinate =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.determinate;
    in
    {
      options.dsqr.darwin.determinate.enable = mkEnableOption "external Determinate-managed Nix install";

      config = mkIf cfg.enable {
        # Let an external Determinate Nix installation own the Nix install layer.
        nix.enable = false;
        ids.gids.nixbld = 350;
      };
    };
}
