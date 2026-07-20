{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkDefault mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.lists) singleton;
      inherit (lib.types) nullOr path;
      cfg = config.dsqr.nixos.tailscale;
      hasAuthKey = cfg.authKeyAgeFile != null && builtins.pathExists cfg.authKeyAgeFile;
    in
    {
      options.dsqr.nixos.tailscale = {
        enable = mkEnableOption "Enable the shared Tailscale baseline";

        authKeyAgeFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Encrypted age file containing the Tailscale auth key.";
        };
      };

      config = mkIf cfg.enable {
        age.secrets.tailscaleAuthKey = mkIf hasAuthKey {
          file = cfg.authKeyAgeFile;
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

        # The upstream autoconnect helper waits for the daemon's BackendState to
        # become Running. During a switch that also restarts networking, the
        # control-plane handshake can exceed systemd's 90-second default even
        # though the node is already authenticated and recovers normally.
        systemd.services.tailscaled-autoconnect = {
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig.TimeoutStartSec = "5min";
        };
      };
    };
}
