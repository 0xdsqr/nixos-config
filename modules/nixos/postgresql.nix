{
  flake.nixosModules.postgresql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatMapStringsSep
        concatStringsSep
        flip
        genAttrs
        getExe
        mkOption
        mkForce
        mkOverride
        types
        unique
        ;
      cfg = config.dsqr.nixos.postgresql;
      resticHosts = config.services.restic.hosts or [ ];
      ensuredRoles = unique (
        cfg.ensure
        ++ [
          "postgres"
          "root"
        ]
      );
      hostAuthRules = concatMapStringsSep "\n" (cidr: "host  all      all  ${cidr} ${cfg.hostAuthMethod}") cfg.allowedCIDRs;
    in
    {
      options.dsqr.nixos.postgresql = {
        ensure = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Databases and matching users to create automatically.";
        };

        listenAddresses = mkOption {
          type = types.listOf types.str;
          default = [
            "127.0.0.1"
            "::1"
          ];
          description = "PostgreSQL addresses to listen on when TCP is enabled.";
        };

        allowedCIDRs = mkOption {
          type = types.listOf types.str;
          default = [
            "127.0.0.1/32"
            "::1/128"
          ];
          description = "CIDRs allowed to authenticate over TCP.";
        };

        hostAuthMethod = mkOption {
          type = types.enum [
            "md5"
            "scram-sha-256"
          ];
          default = "md5";
          description = "Password auth method for TCP clients. Keep md5 until all role passwords are rotated to SCRAM.";
        };

        exporter.listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address the postgres Prometheus exporter listens on.";
        };
      };

      config = {
        services.prometheus.exporters.postgres = {
          enable = true;
          inherit (cfg.exporter) listenAddress;
          runAsLocalSuperUser = true;
        };

        services.restic.backups = genAttrs resticHosts (_: {
          paths = [ "/tmp/postgresql-dump.sql.gz" ];

          backupPrepareCommand = /* sh */ ''
            ${config.services.postgresql.package}/bin/pg_dumpall --clean \
            | ${getExe pkgs.gzip} --rsyncable \
            > /tmp/postgresql-dump.sql.gz
          '';

          backupCleanupCommand = /* sh */ ''
            rm /tmp/postgresql-dump.sql.gz
          '';
        });

        environment.systemPackages = [ config.services.postgresql.package ];

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_18;

          enableJIT = true;
          enableTCPIP = true;

          settings.listen_addresses = mkForce (concatStringsSep "," cfg.listenAddresses);
          authentication = mkOverride 10 /* ini */ ''
            #     DATABASE USER        AUTHENTICATION
            local all      all         peer

            #     DATABASE USER ADDRESS AUTHENTICATION
            ${hostAuthRules}
          '';

          ensureDatabases = cfg.ensure;
          ensureUsers = flip map ensuredRoles (name: {
            inherit name;

            ensureDBOwnership = builtins.elem name cfg.ensure;

            ensureClauses = {
              login = true;
              superuser = name == "postgres" || name == "root";
            };
          });

          initdbArgs = [
            "--locale=C"
            "--encoding=UTF8"
          ];
        };
      };
    };
}
