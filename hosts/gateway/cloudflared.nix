{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ cloudflared ];

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  users.groups.cloudflared = { };

  age.secrets.cloudflaredCredentials = {
    file = ./tunnel.credentials.age;
    path = "/etc/cloudflared/credentials.json";
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "af7ebddc-a096-441c-afe1-ab19bab3d8ab" = {
        credentialsFile = config.age.secrets.cloudflaredCredentials.path;
        default = "http_status:404";
        ingress = {
          "dsqr.dev" = {
            service = "http://192.168.50.240";
            originRequest = {
              httpHostHeader = "dsqr.dev";
            };
          };

          "studio.dsqr.dev" = {
            service = "http://192.168.50.240";
            originRequest = {
              httpHostHeader = "studio.dsqr.dev";
            };
          };

          "vault.dsqr.dev" = {
            service = "http://10.10.30.107:8200";
          };

          "grafana.dsqr.dev" = {
            service = "http://10.10.30.102:8000";
          };
          "prometheus.dsqr.dev" = {
            service = "http://10.10.30.102:9090";
          };

          "rustfs.dsqr.dev" = {
            service = "http://10.10.30.107:9001";
          };
          "s3.dsqr.dev" = {
            service = "http://10.10.30.107:9000";
          };
          "cdn.dsqr.dev" = {
            service = "http://10.10.30.107:9000";
          };

          "tastingswithtay.com" = {
            service = "http://192.168.50.240";
            originRequest = {
              httpHostHeader = "tastingswithtay.com";
            };
          };
          "admin.tastingswithtay.com" = {
            service = "http://192.168.50.240";
            originRequest = {
              httpHostHeader = "admin.tastingswithtay.com";
            };
          };

          "proxmox.dsqr.dev" = {
            service = "https://100.125.141.48:8006";
            originRequest = {
              originServerName = "proxmox.dsqr.dev";
            };
          };

          "opnsense.dsqr.dev" = {
            service = "https://192.168.50.2";
            originRequest = {
              originServerName = "opnsense.dsqr.dev";
            };
          };
        };
      };
    };
  };
}
