{
  flake.darwinModules.shells =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      inherit (pkgs) bashInteractive nushell;
      cfg = config.dsqr.darwin.shells;
    in
    {
      options.dsqr.darwin.shells.enable = mkEnableOption "Darwin login shell registration" // {
        default = true;
      };

      config = mkIf cfg.enable {
        environment.shells = [
          bashInteractive
          nushell
        ];
      };
    };

  flake.nixosModules.shells =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      inherit (pkgs) bashInteractive nushell;
      cfg = config.dsqr.nixos.shells;
    in
    {
      options.dsqr.nixos.shells.enable = mkEnableOption "NixOS login shell defaults" // {
        default = true;
      };

      config = mkIf cfg.enable {
        users.defaultUserShell = nushell;

        environment.shells = [
          bashInteractive
          nushell
        ];
      };
    };
}
