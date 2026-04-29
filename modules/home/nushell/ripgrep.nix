{
  flake.homeModules.ripgrep =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      nuCfg = config.dsqr.home.nu;
      cfg = nuCfg.ripgrep;
    in
    {
      options.dsqr.home.nu.ripgrep.enable = mkEnableOption "ripgrep defaults for Nushell workflows" // {
        default = true;
      };

      config.programs.ripgrep = mkIf (nuCfg.enable && nuCfg.integrations.enable && cfg.enable) {
        enable = true;
        arguments = singleton "--smart-case";
      };
    };
}
