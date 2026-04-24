{
  flake.nixosModules.tailscale =
    {
      config,
      hostMeta,
      lib,
      ...
    }:
    let
      inherit (lib) mkDefault mkIf;
      inherit (lib.lists) singleton;
      authKeyAgeFile = hostMeta.path + "/tailscale.auth-key.age";
      hasAuthKey = builtins.pathExists authKeyAgeFile;
    in
    {
      config = {
        age.secrets.tailscaleAuthKey = mkIf hasAuthKey {
          file = authKeyAgeFile;
          owner = "root";
          mode = "0400";
        };

        services.tailscale = {
          enable = true;
          interfaceName = mkDefault "ts0";
          useRoutingFeatures = mkDefault "both";
          authKeyFile = mkIf hasAuthKey config.age.secrets.tailscaleAuthKey.path;
        };

        networking.firewall.trustedInterfaces = singleton "ts0";

        systemd.services.tailscaled.serviceConfig.Environment = mkIf config.networking.nftables.enable [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];
      };
    };
}
