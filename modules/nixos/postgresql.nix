{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrByPath
    flip
    genAttrs
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
in
{
  config = mkIf cfg.enable {
    services.prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "0.0.0.0";
      runAsLocalSuperUser = true;
    };

    services.restic.backups = genAttrs resticHosts (_: {
      paths = [ "/tmp/postgresql-dump.sql.gz" ];

      backupPrepareCommand = /* sh */ ''
        ${config.services.postgresql.package}/bin/pg_dumpall --clean \
        | ${lib.getExe pkgs.gzip} --rsyncable \
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

      settings.listen_addresses = mkForce "*";
      authentication = mkOverride 10 /* ini */ ''
        #     DATABASE USER        AUTHENTICATION
        local all      all         peer

        #     DATABASE USER ADDRESS AUTHENTICATION
        host  all      all  0.0.0.0/0 md5
        host  all      all  ::/0    md5
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
}
