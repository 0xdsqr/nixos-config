{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
  ];

  dsqr.proxmox.networking = {
    hostName = "gateway";
  };

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  users.groups.cloudflared = { };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "dsqr" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        default = "http_status:404";
        ingress = {
          "db.dsqr.dev" = {
            service = "tcp://192.168.50.27:5432";
          };
          "dsqr.dev/api" = {
            service = "http://192.168.50.27:3001";
          };
          "dsqr.dev" = {
            service = "http://192.168.50.27:8080";
          };
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [ cloudflared ];

  system.stateVersion = "25.05";
}
