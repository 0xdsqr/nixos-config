{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) escapeShellArg;

  postgres = {
    host = "postgres.service.home.arpa";
    port = 5432;
    user = "temporal";
    database = "temporal";
    visibilityDatabase = "temporal_visibility";
    pluginName = "postgres12";
    caFile = "/etc/ssl/certs/ca-certificates.crt";
    passwordEnvVar = "TEMPORAL_POSTGRES_PASSWORD";
  };

  temporalPostgresqlSchema = pkgs.writeShellApplication {
    name = "temporal-postgresql-schema";
    runtimeInputs = [
      config.dsqr.nixos.temporal.package
      config.dsqr.nixos.postgresql.package
      pkgs.gnugrep
    ];
    text = ''
      if [[ -r ${escapeShellArg config.age.secrets.temporalPostgresEnv.path} ]]; then
        set -a
        # shellcheck disable=SC1091
        source ${escapeShellArg config.age.secrets.temporalPostgresEnv.path}
        set +a
      fi

      password_env_var=${escapeShellArg postgres.passwordEnvVar}
      password_value="''${!password_env_var:-}"
      if [[ -z "$password_value" ]]; then
        echo "$password_env_var must be set before running temporal-postgresql-schema" >&2
        exit 1
      fi

      export SQL_HOST=${escapeShellArg postgres.host}
      export SQL_PORT=${escapeShellArg (toString postgres.port)}
      export SQL_USER=${escapeShellArg postgres.user}
      export SQL_PASSWORD="$password_value"
      export SQL_PLUGIN=${escapeShellArg postgres.pluginName}
      export SQL_TLS=true
      export SQL_TLS_CA_FILE=${escapeShellArg postgres.caFile}
      export SQL_TLS_SERVER_NAME=${escapeShellArg postgres.host}
      export SQL_TLS_DISABLE_HOST_VERIFICATION=false
      export PGPASSWORD="$password_value"
      export PGSSLMODE=verify-full
      export PGSSLROOTCERT=${escapeShellArg postgres.caFile}

      setup_schema() {
        local database="$1"
        local schema_dir="$2"

        export SQL_DATABASE="$database"
        if ! psql \
          --host "$SQL_HOST" \
          --port "$SQL_PORT" \
          --username "$SQL_USER" \
          --dbname "$database" \
          --tuples-only \
          --no-align \
          --command "select 1 from information_schema.tables where table_schema = 'public' and table_name = 'schema_version'" \
          | grep --quiet --line-regexp 1; then
          temporal-sql-tool setup-schema --version 0.0
        fi

        temporal-sql-tool update-schema --schema-dir "$schema_dir"
      }

      setup_schema ${escapeShellArg postgres.database} ${escapeShellArg "${config.dsqr.nixos.temporal.package}/share/schema/postgresql/v12/temporal/versioned"}
      setup_schema ${escapeShellArg postgres.visibilityDatabase} ${escapeShellArg "${config.dsqr.nixos.temporal.package}/share/schema/postgresql/v12/visibility/versioned"}
    '';
  };
in
{
  age.secrets.temporalPostgresEnv = {
    file = ./postgres.env.age;
    mode = "0400";
  };

  environment.systemPackages = [ temporalPostgresqlSchema ];

  systemd.services.temporal-postgresql-schema = {
    description = "Setup and upgrade Temporal PostgreSQL schema";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    before = [ "temporal.service" ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = [ config.age.secrets.temporalPostgresEnv.path ];
    };
    script = ''
      exec ${temporalPostgresqlSchema}/bin/temporal-postgresql-schema
    '';
  };
}
