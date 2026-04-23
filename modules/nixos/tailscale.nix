{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      inherit (lib.lists) singleton;
      cfg = config.dsqr.nixos.tailscale;
    in
    {
      config = mkIf cfg.enable {
        age.secrets.tailscaleAuthKey = mkIf (cfg.authKeyAgeFile != null) {
          file = cfg.authKeyAgeFile;
          owner = "root";
          mode = "0400";
        };

        services.tailscale = {
          enable = true;
          inherit (cfg) interfaceName;
          inherit (cfg) useRoutingFeatures;
          authKeyFile = mkIf (cfg.authKeyAgeFile != null) config.age.secrets.tailscaleAuthKey.path;
          inherit (cfg) extraUpFlags;
        };

        networking.firewall.trustedInterfaces = singleton cfg.interfaceName;

        systemd.services.tailscaled.serviceConfig.Environment = mkIf config.networking.nftables.enable [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];
      };
    };
}
