{
  flake.nixosModules.openssh =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.nixos.openssh;
    in
    {
      options.dsqr.nixos.openssh.enable = mkEnableOption "Enable the shared OpenSSH server baseline";

      config = mkIf cfg.enable {
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
      };
    };
}
