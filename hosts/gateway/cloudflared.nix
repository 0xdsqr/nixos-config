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
            service = "https://10.10.30.200";
            originRequest = {
              httpHostHeader = "dsqr.dev";
              noTLSVerify = true;
            };
          };

          "studio.dsqr.dev" = {
            service = "https://10.10.30.200";
            originRequest = {
              httpHostHeader = "studio.dsqr.dev";
              noTLSVerify = true;
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
            service = "https://10.10.30.200";
            originRequest = {
              httpHostHeader = "tastingswithtay.com";
              noTLSVerify = true;
            };
          };
          "admin.tastingswithtay.com" = {
            service = "https://10.10.30.200";
            originRequest = {
              httpHostHeader = "admin.tastingswithtay.com";
              noTLSVerify = true;
            };
          };

          "proxmox.dsqr.dev" = {
            service = "https://10.10.10.109:8006";
            originRequest = {
              noTLSVerify = true;
            };
          };

          "opnsense.dsqr.dev" = {
            service = "https://10.10.10.1";
            originRequest = {
              noTLSVerify = true;
            };
          };

          "tplink.dsqr.dev" = {
            service = "https://10.10.10.2";
            originRequest = {
              noTLSVerify = true;
            };
          };

          "r730xd-idrac.dsqr.dev" = {
            service = "https://10.10.10.105";
            originRequest = {
              noTLSVerify = true;
            };
          };
        };
      };
    };
  };
}
