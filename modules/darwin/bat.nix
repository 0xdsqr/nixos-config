{
  flake.darwinModules.bat =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkOption mkPackageOption;
      inherit (lib.types) bool;
      cfg = config.dsqr.darwin.bat;
    in
    {
      options.dsqr.darwin.bat = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to refresh the bat cache during Darwin activation.";
        };

        package = mkPackageOption pkgs "bat" { };
      };

      config = mkIf cfg.enable {
        system.activationScripts.script.text = mkAfter /* bash */ ''
          ${config.system.activationScripts.bat.text}
        '';

        system.activationScripts.bat.text = /* bash */ ''
          echo "refreshing bat cache..."
          ${getExe cfg.package} cache --build
        '';
      };
    };
}
