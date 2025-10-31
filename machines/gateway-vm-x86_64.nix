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
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  users.groups.cloudflared = {};

  services.cloudflared = {
    enable = true;
    tunnels = {
      "dsqr" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        ingress = {
          "dsqr.dev" = {
            service = "http://192.168.50.223:8080";
          };
        };
        default = "http_status:404";
      };
    };
  };
  environment.systemPackages = with pkgs; [ cloudflared ];

  system.stateVersion = "25.05";
}