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
  # Using named servers (best practice in NixOS 24.05+)
  services.redis.servers.main = {
    enable = true;

    # Bind to localhost only for security
    # Change to "0.0.0.0" if you need external access
    bind = "127.0.0.1";

    # Default port
    port = 6379;

    # Memory management and persistence
    settings = {
      # Set max memory to 256MB (adjust based on your needs)
      maxmemory = "256mb";
      # allkeys-lru = evict least recently used keys when maxmemory is reached
      maxmemory-policy = "allkeys-lru";

      # Persistence: save to disk periodically
      save = [
        "900 1"     # After 900 sec (15 min) if at least 1 key changed
        "300 10"    # After 300 sec (5 min) if at least 10 keys changed
        "60 10000"  # After 60 sec if at least 10000 keys changed
      ];

      # Enable AOF (Append Only File) for better durability
      appendonly = true;
      appendfsync = "everysec"; # fsync every second (good balance)
    };
  };

  environment.systemPackages = with pkgs; [
    redis
  ];

  system.stateVersion = "25.05";
}