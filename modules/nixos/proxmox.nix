{
  flake.nixosModules.proxmox =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      config = {
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
