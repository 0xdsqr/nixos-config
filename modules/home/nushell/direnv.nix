{
  flake.homeModules.direnv =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;
      nuCfg = config.dsqr.home.nu;
      cfg = nuCfg.direnv;

      # direnv's upstream shell test suite can hang during first-time Darwin rebuilds,
      # so we skip checks here to keep workstation bootstrap reliable.
      defaultPackage = pkgs.direnv.overrideAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    in
    {
      options.dsqr.home.nu.direnv = {
        enable = mkEnableOption "direnv integration for Nushell" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = defaultPackage;
          description = "direnv package to use for Nushell integration.";
        };
      };

      config = mkIf (nuCfg.enable && nuCfg.integrations.enable && cfg.enable) {
        home.packages = singleton pkgs.nix-direnv;

        programs.direnv = {
          enable = true;
          inherit (cfg) package;
          silent = false;
          nix-direnv.enable = true;
          enableNushellIntegration = true;
          config = { };
        };
      };
    };
}
