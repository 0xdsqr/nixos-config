{
  flake.homeModules.carapace =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      nuCfg = config.dsqr.home.nu;
      cfg = nuCfg.carapace;
    in
    {
      options.dsqr.home.nu.carapace.enable = mkEnableOption "carapace integration for Nushell" // {
        default = true;
      };

      config.programs.carapace = mkIf (nuCfg.enable && nuCfg.integrations.enable && cfg.enable) {
        enable = true;
        enableNushellIntegration = true;
        ignoreCase = true;
      };
    };
}
