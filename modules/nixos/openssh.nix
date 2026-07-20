{
  flake.nixosModules.openssh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.nixos.openssh;
    in
    {
      options.dsqr.nixos.openssh.enable = mkEnableOption "Enable the shared OpenSSH server baseline";

      config = mkIf cfg.enable {
        environment.systemPackages = [ pkgs.ghostty.terminfo ];

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
