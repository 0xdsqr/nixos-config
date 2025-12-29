{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.self.nixosModules.rustfs
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "cellar";
    staticIP = {
      enable = true;
      address = "192.168.50.37";
    };
    firewall.allowedTCPPorts = [
      5432 # PostgreSQL
      9000 # RustFS S3 API
      9001 # RustFS Console
    ];
  };

  # RustFS S3-compatible object storage
  services.dsqr-rustfs = {
    enable = true;
    package = inputs.rustfs.packages.${pkgs.system}.default;
    address = "0.0.0.0";
    consoleAddress = "0.0.0.0";
    # TODO: Use SOPS for credentials in production
    # rootCredentialsFile = config.sops.secrets."rustfs/credentials".path;
  };

  # PostgreSQL database
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    enableTCPIP = true;

    authentication = lib.mkForce ''
      # Local unix socket
      local   all             all                                     peer
      # Local network (cellar's subnet)
      host    all             all             192.168.50.0/24         scram-sha-256
      # Localhost
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';

    settings = {
      # Listen on all interfaces
      listen_addresses = "*";
      port = 5432;
      max_connections = 100;

      # Memory (conservative for VM)
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      work_mem = "4MB";
      maintenance_work_mem = "64MB";

      # WAL
      wal_level = "replica";
      max_wal_size = "1GB";
      min_wal_size = "80MB";

      # Logging (useful for debugging)
      log_statement = "ddl";
      log_min_duration_statement = 1000;

      # Security
      password_encryption = "scram-sha-256";
    };

    # Initial setup
    ensureDatabases = [ "cellar" ];
    ensureUsers = [
      {
        name = "cellar";
        ensureDBOwnership = true;
      }
    ];
  };

  system.stateVersion = "25.05";
}
