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
        attrByPath
        concatMapStringsSep
        concatStringsSep
        flip
        genAttrs
        getExe
        mkIf
        mkForce
        mkOverride
        unique
        ;
      cfg = config.dsqr.nixos.postgresql;
      resticHosts = attrByPath [ "services" "restic" "hosts" ] [ ] config;
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
