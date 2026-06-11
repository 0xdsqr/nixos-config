{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) escapeShellArg;

  postgres = {
    host = "127.0.0.1";
    port = 5432;
    user = "temporal";
    database = "temporal";
    visibilityDatabase = "temporal_visibility";
    pluginName = "postgres12";
    sslMode = "disable";
    passwordEnvVar = "TEMPORAL_POSTGRES_PASSWORD";
  };

  psql = "${config.services.postgresql.package}/bin/psql";

  temporalPostgresqlSchema = pkgs.writeShellApplication {
    name = "temporal-postgresql-schema";
    runtimeInputs = [
      config.dsqr.nixos.temporal.package
      config.services.postgresql.package
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
      export SQL_CONNECT_ATTRIBUTES=${escapeShellArg "sslmode=${postgres.sslMode}"}
      export PGPASSWORD="$password_value"
      export PGSSLMODE=${escapeShellArg postgres.sslMode}

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

  systemd.services.temporal-postgresql-bootstrap = {
    description = "Prepare PostgreSQL role and databases for Temporal";
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    before = [
      "temporal-postgresql-schema.service"
      "temporal.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      EnvironmentFile = [ config.age.secrets.temporalPostgresEnv.path ];
    };
    script = ''
      set -euo pipefail

      password_env_var=${escapeShellArg postgres.passwordEnvVar}
      password_value="''${!password_env_var:-}"
      if [[ -z "$password_value" ]]; then
        echo "$password_env_var must be set before bootstrapping Temporal PostgreSQL" >&2
        exit 1
      fi

      ${psql} --dbname postgres --set ON_ERROR_STOP=1 <<SQL
      \set temporal_password $password_value

      DO \$\$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${postgres.user}') THEN
          CREATE ROLE "${postgres.user}" LOGIN;
        END IF;
      END
      \$\$;

      ALTER ROLE "${postgres.user}" WITH LOGIN PASSWORD :'temporal_password';
      SQL

      if ! ${psql} \
        --dbname postgres \
        --tuples-only \
        --no-align \
        --command "SELECT 1 FROM pg_database WHERE datname = '${postgres.database}'" \
        | ${pkgs.gnugrep}/bin/grep --quiet --line-regexp 1; then
        ${psql} \
          --dbname postgres \
          --set ON_ERROR_STOP=1 \
          --command 'CREATE DATABASE "${postgres.database}" OWNER "${postgres.user}"'
      fi

      if ! ${psql} \
        --dbname postgres \
        --tuples-only \
        --no-align \
        --command "SELECT 1 FROM pg_database WHERE datname = '${postgres.visibilityDatabase}'" \
        | ${pkgs.gnugrep}/bin/grep --quiet --line-regexp 1; then
        ${psql} \
          --dbname postgres \
          --set ON_ERROR_STOP=1 \
          --command 'CREATE DATABASE "${postgres.visibilityDatabase}" OWNER "${postgres.user}"'
      fi

      ${psql} --dbname postgres --set ON_ERROR_STOP=1 <<SQL
      ALTER DATABASE "${postgres.database}" OWNER TO "${postgres.user}";
      ALTER DATABASE "${postgres.visibilityDatabase}" OWNER TO "${postgres.user}";
      GRANT ALL PRIVILEGES ON DATABASE "${postgres.database}" TO "${postgres.user}";
      GRANT ALL PRIVILEGES ON DATABASE "${postgres.visibilityDatabase}" TO "${postgres.user}";
      SQL
    '';
  };

  systemd.services.temporal-postgresql-schema = {
    description = "Setup and upgrade Temporal PostgreSQL schema";
    requires = [ "temporal-postgresql-bootstrap.service" ];
    after = [ "temporal-postgresql-bootstrap.service" ];
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
