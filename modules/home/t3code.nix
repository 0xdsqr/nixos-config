{
  flake.homeModules.t3code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.t3code;
    in
    {
      options.dsqr.home.t3code = {
        enable = mkEnableOption "T3 Code desktop app and CLI";

        package = mkOption {
          type = package;
          default = pkgs.t3code;
          description = "T3 Code package to install.";
        };
      };

      config = mkIf cfg.enable {
        programs.t3code = {
          enable = true;
          inherit (cfg) package;
        };
      };
    };
}
