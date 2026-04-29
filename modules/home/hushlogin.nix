{
  flake.homeModules.hushlogin =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.hushlogin;
    in
    {
      options.dsqr.home.hushlogin.enable = mkEnableOption "a quiet login shell" // {
        default = true;
      };

      config = mkIf cfg.enable { home.file.".hushlogin".text = ""; };
    };
}
