{
  flake.darwinModules.sudo =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.sudo;
    in
    {
      options.dsqr.darwin.sudo.enable = mkEnableOption "Darwin sudo defaults" // {
        default = true;
      };

      config = mkIf cfg.enable {
        security.pam.services.sudo_local = {
          enable = true;
          touchIdAuth = true;
        };

        security.sudo.extraConfig = /* sudo */ ''
          Defaults lecture = never
          Defaults pwfeedback
          Defaults env_keep += "EDITOR PATH"
        '';
      };
    };
}
