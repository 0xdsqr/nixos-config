{
  flake.nixosModules.postgresql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        attrNames
        genAttrs
        mapAttrsToList
        optionalAttrs
        ;
      inherit (lib.lists) optional unique;
      inherit (lib.meta) getExe;
      inherit (lib.modules)
        mkAfter
        mkForce
        mkIf
        mkOverride
        ;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatMapStringsSep concatStringsSep escapeShellArg;
      inherit (lib.trivial) flip;
      inherit (lib.types)
        attrsOf
        bool
        enum
        listOf
        package
        str
        submodule
        ;
      cfg = config.dsqr.nixos.postgresql;
      resticHosts = config.services.restic.hosts or [ ];
      databaseNames = attrNames cfg.databases;
      databaseOwners = mapAttrsToList (_: database: database.owner) cfg.databases;
      membershipAssertions = builtins.concatLists (
        mapAttrsToList (
          name: role:
          map (membership: {
            assertion = builtins.hasAttr membership cfg.roles;
            message = "PostgreSQL role ${name} references undeclared membership ${membership}.";
          }) role.memberships
        ) cfg.roles
      );
      runtimeAccessAssertions = builtins.concatLists (
        mapAttrsToList (
          databaseName: database:
          map (roleName: {
            assertion = builtins.hasAttr roleName cfg.roles && !cfg.roles.${roleName}.login;
            message = "PostgreSQL database ${databaseName} runtime role ${roleName} must be declared with login = false.";
          }) database.runtimeAccessRoles
        ) cfg.databases
      );
      legacyRoleNames = unique (cfg.ensure ++ optional (cfg.ensure != [ ]) "postgres" ++ optional (cfg.ensure != [ ]) "root");
      catalogRoleNames = builtins.filter (
        name: name != config.services.postgresql.superUser && !builtins.elem name legacyRoleNames
      ) (unique (databaseOwners ++ attrNames cfg.roles));
      defaultRoleClauses = {
        login = true;
        superuser = false;
        createdb = false;
        createrole = false;
        replication = false;
        bypassrls = false;
      };
      legacyUsers = flip map legacyRoleNames (name: {
        inherit name;

        ensureDBOwnership = builtins.elem name cfg.ensure;
        ensureClauses = {
          login = true;
          superuser = name == "postgres" || name == "root";
        };
      });
      catalogUsers = flip map catalogRoleNames (name: {
        inherit name;
        ensureClauses = defaultRoleClauses // builtins.intersectAttrs defaultRoleClauses (cfg.roles.${name} or { });
      });
      quoteIdentifier = value: "\"${builtins.replaceStrings [ "\"" ] [ "\"\"" ] value}\"";
      membershipCommands = concatMapStringsSep "\n" (
        name:
        concatMapStringsSep "\n" (
          membership:
          let
            statement = "GRANT ${quoteIdentifier membership} TO ${quoteIdentifier name};";
          in
          ''
            ${cfg.package}/bin/psql --dbname=postgres --set=ON_ERROR_STOP=1 --command=${escapeShellArg statement}
          ''
        ) (cfg.roles.${name}.memberships or [ ])
      ) (attrNames cfg.roles);
      ownershipCommands = concatMapStringsSep "\n" (
        name:
        let
          owner = cfg.databases.${name}.owner;
          statement = "ALTER DATABASE ${quoteIdentifier name} OWNER TO ${quoteIdentifier owner};";
        in
        ''
          ${cfg.package}/bin/psql --dbname=postgres --set=ON_ERROR_STOP=1 --command=${escapeShellArg statement}
        ''
      ) databaseNames;
      runtimeAccessCommands = concatMapStringsSep "\n" (
        name:
        let
          database = cfg.databases.${name};
          owner = quoteIdentifier database.owner;
        in
        concatMapStringsSep "\n" (
          roleName:
          let
            role = quoteIdentifier roleName;
            databaseName = quoteIdentifier name;
            databaseStatements = concatStringsSep " " [
              "REVOKE CONNECT ON DATABASE ${databaseName} FROM PUBLIC;"
              "GRANT CONNECT ON DATABASE ${databaseName} TO ${role};"
            ];
            schemaStatements = concatStringsSep " " [
              "REVOKE CREATE ON SCHEMA public FROM PUBLIC;"
              "GRANT USAGE ON SCHEMA public TO ${role};"
              "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${role};"
              "GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO ${role};"
              "ALTER DEFAULT PRIVILEGES FOR ROLE ${owner} IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${role};"
              "ALTER DEFAULT PRIVILEGES FOR ROLE ${owner} IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO ${role};"
            ];
          in
          ''
            ${cfg.package}/bin/psql --dbname=postgres --set=ON_ERROR_STOP=1 --command=${escapeShellArg databaseStatements}
            ${cfg.package}/bin/psql --dbname=${escapeShellArg name} --set=ON_ERROR_STOP=1 --command=${escapeShellArg schemaStatements}
          ''
        ) database.runtimeAccessRoles
      ) databaseNames;
      extensionCommands = concatMapStringsSep "\n" (
        name:
        concatMapStringsSep "\n" (
          extension:
          let
            statement = "CREATE EXTENSION IF NOT EXISTS ${quoteIdentifier extension};";
          in
          ''
            ${cfg.package}/bin/psql --dbname=${escapeShellArg name} --set=ON_ERROR_STOP=1 --command=${escapeShellArg statement}
          ''
        ) cfg.databases.${name}.extensions
      ) databaseNames;
      hostAuthRules = concatMapStringsSep "\n" (cidr: "host  all      all  ${cidr} ${cfg.hostAuthMethod}") cfg.allowedCIDRs;
      extraHostAuthRules = concatMapStringsSep "\n" (
        rule: "${rule.type}  ${rule.database}  ${rule.user}  ${rule.address}  ${rule.method}"
      ) cfg.hostAuthenticationRules;
      waitForTlsFiles = pkgs.writeShellApplication {
        name = "postgresql-wait-for-tls-files";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          for _ in $(seq 1 240); do
            if [[ -s ${escapeShellArg cfg.tls.certificateFile} && -s ${escapeShellArg cfg.tls.privateKeyFile} ]]; then
              exit 0
            fi

            sleep 0.25
          done

          echo "PostgreSQL TLS certificate files were not rendered within 60 seconds." >&2
          exit 1
        '';
      };
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
          description = "Legacy databases and matching users to create automatically.";
        };

        databases = mkOption {
          type = attrsOf (
            submodule (
              { name, ... }: {
                options = {
                  owner = mkOption {
                    type = str;
                    default = name;
                    description = "Role that owns the database.";
                  };

                  extensions = mkOption {
                    type = listOf str;
                    default = [ ];
                    description = "Extensions to create when they are available in the PostgreSQL package.";
                  };

                  runtimeAccessRoles = mkOption {
                    type = listOf str;
                    default = [ ];
                    description = ''
                      Non-login roles granted CONNECT plus runtime DML access to the public schema,
                      including matching default privileges for objects created by the database owner.
                    '';
                  };
                };
              }
            )
          );
          default = { };
          description = "Databases, owners, and extensions to reconcile.";
        };

        roles = mkOption {
          type = attrsOf (submodule {
            options = {
              login = mkOption {
                type = bool;
                default = true;
              };

              superuser = mkOption {
                type = bool;
                default = false;
              };

              createdb = mkOption {
                type = bool;
                default = false;
              };

              createrole = mkOption {
                type = bool;
                default = false;
              };

              replication = mkOption {
                type = bool;
                default = false;
              };

              bypassrls = mkOption {
                type = bool;
                default = false;
              };

              memberships = mkOption {
                type = listOf str;
                default = [ ];
                description = "Roles granted to this role during PostgreSQL setup.";
              };
            };
          });
          default = { };
          description = "Role overrides and roles that do not own a database.";
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

        hostAuthenticationRules = mkOption {
          type = listOf (submodule {
            options = {
              type = mkOption {
                type = enum [
                  "host"
                  "hostssl"
                  "hostnossl"
                ];
                default = "host";
              };

              database = mkOption { type = str; };
              user = mkOption { type = str; };
              address = mkOption { type = str; };

              method = mkOption {
                type = enum [
                  "md5"
                  "scram-sha-256"
                  "trust"
                ];
                default = "scram-sha-256";
              };
            };
          });
          default = [ ];
          description = "Additional structured pg_hba host rules.";
        };

        tls = {
          enable = mkEnableOption "PostgreSQL TLS";

          certificateFile = mkOption {
            type = str;
            default = "/var/lib/postgresql/tls/server.crt";
            description = "Path to the PostgreSQL listener certificate and CA chain.";
          };

          privateKeyFile = mkOption {
            type = str;
            default = "/var/lib/postgresql/tls/server.key";
            description = "Path to the PostgreSQL listener private key.";
          };

          minimumProtocolVersion = mkOption {
            type = enum [
              "TLSv1.2"
              "TLSv1.3"
            ];
            default = "TLSv1.2";
            description = "Oldest TLS protocol accepted by PostgreSQL.";
          };
        };

        exporter.listenAddress = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Address the postgres Prometheus exporter listens on.";
        };
      };

      config = mkIf cfg.enable {
        assertions = membershipAssertions ++ runtimeAccessAssertions;

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

          settings = {
            listen_addresses = mkForce (concatStringsSep "," cfg.listenAddresses);
          }
          // optionalAttrs cfg.tls.enable {
            ssl = true;
            ssl_cert_file = cfg.tls.certificateFile;
            ssl_key_file = cfg.tls.privateKeyFile;
            ssl_min_protocol_version = cfg.tls.minimumProtocolVersion;
          };
          authentication = mkOverride 10 /* ini */ ''
            #     DATABASE USER        AUTHENTICATION
            local all      all         peer

            #     DATABASE USER ADDRESS AUTHENTICATION
            ${hostAuthRules}
            ${extraHostAuthRules}
          '';

          ensureDatabases = unique (cfg.ensure ++ databaseNames);
          ensureUsers = legacyUsers ++ catalogUsers;

          initdbArgs = [
            "--locale=C"
            "--encoding=UTF8"
          ];
        };

        systemd.services.postgresql-setup.script = mkAfter ''
          ${ownershipCommands}
          ${extensionCommands}
          ${membershipCommands}
          ${runtimeAccessCommands}
        '';

        systemd.services.postgresql.serviceConfig.ExecStartPre = mkIf cfg.tls.enable [ "${lib.getExe waitForTlsFiles}" ];
      };
    };
}
