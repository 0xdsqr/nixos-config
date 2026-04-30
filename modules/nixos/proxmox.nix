{
  flake.nixosModules.proxmox =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkDefault mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.nixos.proxmox;
    in
    {
      options.dsqr.nixos.proxmox.enable = mkEnableOption "Enable the shared Proxmox guest baseline";

      config = mkIf cfg.enable {
        services.timesyncd.enable = true;

        services.cloud-init.enable = false;
        services.cloud-init.network.enable = false;

        networking = {
          interfaces.ens18.useDHCP = mkDefault true;
        };

        services.qemuGuest.enable = true;
      };
    };
}
