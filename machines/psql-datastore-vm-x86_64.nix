{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  dbIp = "192.168.50.53";
  lanCidr = "192.168.50.0/24";

  databases = {
    fidara = {
      connectionLimit = 20;
      password = "SCRAM-SHA-256$REPLACE_ME_FIDARA";
    };
  };

  adminRole = {
    name = "db_admin";
    connectionLimit = 5;
    password = "SCRAM-SHA-256$REPLACE_ME_DB_ADMIN";
  };

  dbNames = builtins.attrNames databases;

  mkAppUser = name: {
    name = name;
    ensureDBOwnership = true;
    ensureClauses = {
      login = true;
      password = databases.${name}.password;
      connection_limit = databases.${name}.connectionLimit;
    };
  };

  appUsers = map mkAppUser dbNames;

  adminUser = {
    name = adminRole.name;
    ensureClauses = {
      login = true;
      createrole = true;
      createdb = true;
      replication = false;
      password = adminRole.password;
      connection_limit = adminRole.connectionLimit;
    };
  };

  pgbouncerDatabases = builtins.listToAttrs (
    map (name: {
      name = name;
      value = "host=127.0.0.1 port=5432 dbname=${name}";
    }) dbNames
  );
in
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "psql-datastore";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 5432 6432 ];
    extraCommands = ''
    iptables -A INPUT -p tcp --dport 5432 -s 127.0.0.1 -j ACCEPT
  iptables -A INPUT -p tcp --dport 5432 ! -s ${lanCidr} -j DROP
  iptables -A INPUT -p tcp --dport 6432 -s 127.0.0.1 -j ACCEPT
  iptables -A INPUT -p tcp --dport 6432 ! -s ${lanCidr} -j DROP
    '';
  };

  environment.systemPackages = with pkgs; [
    postgresql_18
    pgbouncer
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;

    dataDir = "/var/lib/postgresql/18";

    ensureDatabases = dbNames;
    ensureUsers = appUsers ++ [ adminUser ];

    settings = {
      listen_addresses = lib.mkForce "${dbIp},127.0.0.1";
      port = 5432;

      password_encryption = "scram-sha-256";

      logging_collector = true;
      log_destination = "stderr";
      log_line_prefix = "%m [%p] %q%u@%d ";
      log_connections = true;
      log_disconnections = true;
      log_min_duration_statement = "250ms";
      log_checkpoints = true;
      log_lock_waits = true;

      wal_level = "replica";
      max_wal_senders = 3;
      max_replication_slots = 3;
      archive_mode = true;
      archive_command =
        "test ! -f /var/lib/postgresql/archive/%f && cp %p /var/lib/postgresql/archive/%f";

      max_connections = 100;
      shared_buffers = "1GB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "256MB";
      work_mem = "16MB";
      random_page_cost = "1.1";
      effective_io_concurrency = "200";

      checkpoint_completion_target = "0.9";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };

    authentication = lib.mkOverride 10 ''
      local   all             postgres                                peer
      local   all             all                                     peer
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ${lanCidr}              scram-sha-256
    '';

    extensions = ps: with ps; [
      pgvector
      postgis
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/postgresql/archive 0700 postgres postgres - -"
    "d /var/backups/postgres 0750 postgres postgres - -"
  ];

  services.pgbouncer = {
    enable = true;

    settings = {
      databases = pgbouncerDatabases;

      pgbouncer = {
        listen_addr = dbIp;
        listen_port = 6432;

        auth_type = "scram-sha-256";
        auth_file = "/etc/pgbouncer/userlist.txt";

        pool_mode = "transaction";

        max_client_conn = 500;
        default_pool_size = 20;
        reserve_pool_size = 5;

        server_reset_query = "DISCARD ALL";
        ignore_startup_parameters = "extra_float_digits";
      };
    };
  };

  environment.etc."pgbouncer/userlist.txt".text = ''
    "fidara" "SCRAM-SHA-256$REPLACE_ME_FIDARA"
    "db_admin" "SCRAM-SHA-256$REPLACE_ME_DB_ADMIN"
  '';

  systemd.services.pgbouncer.after = [ "postgresql.service" ];
  systemd.services.pgbouncer.requires = [ "postgresql.service" ];

  system.stateVersion = "25.05";
}
