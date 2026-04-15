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
    file = ./credentials.json.age;
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

          "admin.dsqr.dev" = {
            service = "http://192.168.50.240";
            originRequest = {
              httpHostHeader = "admin.dsqr.dev";
            };
          };

          "grafana.dsqr.dev" = {
            service = "http://192.168.50.70:8000";
          };
          "prometheus.dsqr.dev" = {
            service = "http://192.168.50.70:9090";
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
