{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  gatewaySecretsPresent = builtins.pathExists ../secrets/hosts/gateway-vm-x86_64.sops.yaml;
in
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "gateway";
  networking.domain = "dsqr.dev";
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  users.groups.cloudflared = { };

  # Only enable cloudflared secrets if the sops file exists locally
  # (keeps eval working in clean clones without secrets).
  sops = lib.mkIf gatewaySecretsPresent {
    defaultSopsFile = ../secrets/hosts/gateway-vm-x86_64.sops.yaml;
    secrets."cloudflared/credentials.json" = { };
  };

  environment.etc = lib.mkIf gatewaySecretsPresent {
    "cloudflared/credentials.json".source = config.sops.secrets."cloudflared/credentials.json".path;
  };

  services.cloudflared = lib.mkIf gatewaySecretsPresent {
    enable = true;
    tunnels = {
      "dsqr" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        default = "http_status:404";
        ingress = {
          "dsqr.dev" = {
            service = "http://192.168.50.27:8080";
          };
          "admin.dsqr.dev" = {
            service = "http://192.168.50.27:8080";
          };
          "teaser.dsqr.dev" = {
            service = "http://192.168.50.27:3010";
            originRequest = {
              httpHostHeader = "localhost";
            };
          };
          # CDN endpoint for static files (goes through Nginx to MinIO)
          "cdn.dsqr.dev" = {
            service = "http://192.168.50.38:9001";
            originRequest = {
              httpHostHeader = "localhost";
            };
          };

          # Direct MinIO S3 API access
          "s3.dsqr.dev" = {
            service = "http://192.168.50.38:9000";
          };

          # MinIO Console (Web UI)
          "rustfs.dsqr.dev" = {
            service = "http://192.168.50.38:9001";
          };
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [ cloudflared ];

  system.stateVersion = "25.05";
}
