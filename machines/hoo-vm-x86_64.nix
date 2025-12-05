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

  networking.hostName = "hoo";
  networking.domain = "dsqr.dev";
  networking.firewall.allowedTCPPorts = [ 22 80 443 8080 3000 3001 3002 ];

  # Redis server configuration
  services.redis.servers.main = {
    enable = true;

    # Bind to localhost only for security
    bind = "127.0.0.1";

    # Default port
    port = 6379;

    settings = {
      # RDB Persistence: Redis expects these as strings
      save = [
        "900 1"       # After 900 sec if at least 1 key changed
        "300 10"      # After 300 sec if at least 10 keys changed
        "60 10000"    # After 60 sec if at least 10000 keys changed
      ];

      # Memory management
      maxmemory = "256mb";
      maxmemory-policy = "allkeys-lru";

      # AOF Persistence
      appendonly = "yes";
      appendfsync = "everysec";
    };
  };

  environment.systemPackages = with pkgs; [
    redis
  ];

  system.stateVersion = "25.05";
}
