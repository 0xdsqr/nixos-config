{ config, pkgs, ... }:
let
  tunnelId = "9c851b2c-8644-40a5-8cf4-ae7f63f4a20c";
in
{
  environment.systemPackages = with pkgs; [ cloudflared ];

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  users.groups.cloudflared = { };

  age.secrets.cloudflaredTunnelToken = {
    file = ./cloudflared.token.age;
    path = "/run/agenix/cloudflaredTunnelToken";
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  systemd.services.cloudflared-managed-tunnel = {
    description = "Cloudflare managed tunnel (${tunnelId})";
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
      ExecStart = "${pkgs.bash}/bin/bash -ec 'exec ${pkgs.cloudflared}/bin/cloudflared tunnel run --token \"$(cat ${config.age.secrets.cloudflaredTunnelToken.path})\"'";
    };
  };
}
