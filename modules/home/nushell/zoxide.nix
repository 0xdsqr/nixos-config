{
  flake.homeModules.zoxide =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      nuCfg = config.dsqr.home.nu;
      cfg = nuCfg.zoxide;
    in
    {
      options.dsqr.home.nu.zoxide.enable = mkEnableOption "zoxide integration for Nushell" // {
        default = true;
      };

      config.programs.zoxide = mkIf (nuCfg.enable && nuCfg.integrations.enable && cfg.enable) {
        enable = true;
        enableNushellIntegration = true;
        options = [
          "--cmd"
          "cd"
        ];
      };
    };
}
