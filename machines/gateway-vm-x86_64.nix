{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
  ];

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

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

  environment.etc."cloudflared/credentials.json".text = ''
    {"AccountTag":"f8913f78ee578f0e62ccb9ad8a89c60f","TunnelSecret":"UwIcahBhAPnYtnSOkqTPoyZe5XBDQ7Xqx8Icda7BQpw=","TunnelID":"7bac09be-28a3-4d74-b4a8-76c8cc5af490","Endpoint":""}
  '';

  services.cloudflared = {
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
