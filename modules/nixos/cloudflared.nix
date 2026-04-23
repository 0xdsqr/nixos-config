{
  flake.nixosModules.cloudflared =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkMerge optional;
      cfg = config.dsqr.nixos.cloudflared;
    in
    {
      config = mkMerge [
        {
          assertions = optional cfg.enable {
            assertion = cfg.tokenAgeFile != null;
            message = "dsqr.nixos.cloudflared.tokenAgeFile must be set when dsqr.nixos.cloudflared.enable = true;";
          };
        }

        (mkIf (cfg.enable && cfg.tokenAgeFile != null) {
          environment.systemPackages = [ pkgs.cloudflared ];

          users.users.cloudflared = {
            group = "cloudflared";
            isSystemUser = true;
            home = "/var/lib/cloudflared";
            createHome = true;
          };

          users.groups.cloudflared = { };

          age.secrets.cloudflaredTunnelToken = {
            file = cfg.tokenAgeFile;
            path = "/run/agenix/cloudflaredTunnelToken";
            owner = "cloudflared";
            group = "cloudflared";
            mode = "0400";
          };

          systemd.services.cloudflared-managed-tunnel = {
            description = "Cloudflare managed tunnel (${cfg.tunnelName}, ${cfg.tunnelId})";
            after = [
              "network.target"
              "network-online.target"
            ];
            wants = [
              "network.target"
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "cloudflared";
              Group = "cloudflared";
              Restart = "on-failure";
              RestartSec = "5s";
              WorkingDirectory = "/var/lib/cloudflared";
              StateDirectory = "cloudflared";
              # Cloudflare pushes ingress config from the control plane, so the
              # host only needs to run `tunnel run --token ...`.
              ExecStart = "${pkgs.bash}/bin/bash -ec 'exec ${pkgs.cloudflared}/bin/cloudflared tunnel run --token \"$(cat ${config.age.secrets.cloudflaredTunnelToken.path})\"'";
            };
          };
        })
      ];
    };
}
