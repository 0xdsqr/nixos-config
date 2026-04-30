{
  flake.nixosModules.postgresql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) unique;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkForce mkIf mkOverride;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatMapStringsSep concatStringsSep;
      inherit (lib.trivial) flip;
      inherit (lib.types)
        enum
        listOf
        package
        str
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
        enable = mkEnableOption "Enable PostgreSQL";

        package = mkOption {
          type = package;
          default = pkgs.postgresql_18;
          defaultText = "pkgs.postgresql_18";
          description = "PostgreSQL package to run.";
        };

        gzipPackage = mkOption {
          type = package;
          default = pkgs.gzip;
          defaultText = "pkgs.gzip";
          description = "gzip package used for restic dump preparation.";
        };

        ensure = mkOption {
          type = listOf str;
          default = [ ];
          description = "Databases and matching users to create automatically.";
        };

        listenAddresses = mkOption {
          type = listOf str;
          default = [
            "127.0.0.1"
            "::1"
          ];
          description = "PostgreSQL addresses to listen on when TCP is enabled.";
        };

        allowedCIDRs = mkOption {
          type = listOf str;
          default = [
            "127.0.0.1/32"
            "::1/128"
          ];
          description = "CIDRs allowed to authenticate over TCP.";
        };

        hostAuthMethod = mkOption {
          type = enum [
            "md5"
            "scram-sha-256"
          ];
          default = "md5";
          description = "Password auth method for TCP clients. Keep md5 until all role passwords are rotated to SCRAM.";
        };

        exporter.listenAddress = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Address the postgres Prometheus exporter listens on.";
        };
      };

      config = mkIf cfg.enable {
        services.prometheus.exporters.postgres = {
          enable = true;
          inherit (cfg.exporter) listenAddress;
          runAsLocalSuperUser = true;
        };

        services.restic.backups = genAttrs resticHosts (_: {
          paths = [ "/tmp/postgresql-dump.sql.gz" ];

          backupPrepareCommand = /* sh */ ''
            ${config.services.postgresql.package}/bin/pg_dumpall --clean \
            | ${getExe cfg.gzipPackage} --rsyncable \
            > /tmp/postgresql-dump.sql.gz
          '';

          backupCleanupCommand = /* sh */ ''
            rm /tmp/postgresql-dump.sql.gz
          '';
        });

        environment.systemPackages = [ config.services.postgresql.package ];

        services.postgresql = {
          enable = true;
          inherit (cfg) package;

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
