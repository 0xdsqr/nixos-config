{
  flake.darwinModules.hostname =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
      cfg = config.dsqr.darwin.hostname;
    in
    {
      options.dsqr.darwin.hostname.smb.enable = mkEnableOption "SMB NetBIOS hostname defaults";

      config = mkIf cfg.smb.enable {
        system.defaults.smb = {
          NetBIOSName = config.networking.hostName;
          ServerDescription = config.networking.hostName;
        };
      };
    };
}
