{
  flake.nixosModules.backup-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe getExe';
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) ints path str;

      cfg = config.dsqr.nixos.backup.server;
      metricsDirectory = "/var/lib/alloy/textfile";
      repositoryEnvironment = config.age.secrets."pgbackrest-repository-environment".path;
      pgBackRest = pkgs.writeShellApplication {
        name = "pgbackrest-secure";
        runtimeInputs = [ pkgs.pgbackrest ];
        text = ''
          set -a
          # shellcheck disable=SC1091
          source ${repositoryEnvironment}
          set +a

          exec ${getExe pkgs.pgbackrest} "$@"
        '';
      };
      authorizedPgBackRest = pkgs.writeShellApplication {
        name = "pgbackrest-authorized-command";
        text = ''
          if ! ${getExe' pkgs.util-linux "mountpoint"} --quiet ${lib.escapeShellArg cfg.rootDirectory}; then
            echo "The backup repository filesystem is not mounted." >&2
            exit 1
          fi

          if [[ "''${SSH_ORIGINAL_COMMAND:-}" != *" "* ]]; then
            echo "Only the pgBackRest remote protocol is allowed." >&2
            exit 1
          fi

          # pgBackRest sends its executable path followed by protocol arguments.
          # Keep the executable fixed while passing only those arguments through.
          # shellcheck disable=SC2086
          exec ${getExe pgBackRest} ''${SSH_ORIGINAL_COMMAND#* }
        '';
      };
    in
    {
      options.dsqr.nixos.backup.server = {
        enable = mkEnableOption "the application-consistent backup repository";

        rootDirectory = mkOption {
          type = str;
          default = "/var/lib/backup";
          description = "Root directory for backup repositories and recovery artifacts.";
        };

        pgBackRest = {
          enable = mkEnableOption "the pgBackRest repository";

          authorizedKey = mkOption {
            type = str;
            description = "Dedicated public key authorized to run only the pgBackRest remote protocol.";
          };

          repositoryEnvironmentAgeFile = mkOption {
            type = path;
            description = "Encrypted environment file containing the pgBackRest repository cipher passphrase.";
          };

          retentionFull = mkOption {
            type = ints.positive;
            default = 2;
            description = "Number of full PostgreSQL backup sets to retain.";
          };

          retentionDiff = mkOption {
            type = ints.positive;
            default = 14;
            description = "Number of differential PostgreSQL backups to retain.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.pgBackRest.enable;
            message = "The backup server currently requires the pgBackRest repository role.";
          }
        ];

        age.secrets."pgbackrest-repository-environment" = {
          file = cfg.pgBackRest.repositoryEnvironmentAgeFile;
          owner = "root";
          group = "pgbackrest";
          mode = "0440";
        };

        services.pgbackrest = {
          enable = true;

          repos.localhost = {
            path = "${cfg.rootDirectory}/postgresql";
            bundle = true;
            block = true;
            cipher-type = "aes-256-cbc";
            retention-full = cfg.pgBackRest.retentionFull;
            retention-diff = cfg.pgBackRest.retentionDiff;
            retention-archive-type = "full";
          };

          settings = {
            process-max = 2;
            compress-type = "zst";
            compress-level = 3;
          };
          stanzas.default.settings = { };
        };

        users.users.pgbackrest.openssh.authorizedKeys.keys = [
          ''restrict,command="${getExe authorizedPgBackRest}" ${cfg.pgBackRest.authorizedKey}''
        ];

        systemd.tmpfiles.rules = [
          "d ${cfg.rootDirectory} 0710 root pgbackrest -"
          "d ${cfg.rootDirectory}/bootstrap 0700 root root -"
          "d ${cfg.rootDirectory}/postgresql 0750 pgbackrest pgbackrest -"
        ];

        systemd.services.pgbackrest-repository-mount = {
          description = "Validate the backup repository filesystem";
          wantedBy = [ "multi-user.target" ];
          after = [ "var-lib-backup.mount" ];
          requires = [ "var-lib-backup.mount" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${getExe' pkgs.util-linux "mountpoint"} --quiet ${cfg.rootDirectory}";
          };
        };

        systemd.services.pgbackrest-backup-metrics = {
          description = "Publish pgBackRest backup freshness metrics";
          after = [ "pgbackrest-repository-mount.service" ];
          requires = [ "pgbackrest-repository-mount.service" ];
          path = [
            pgBackRest
            pkgs.coreutils
            pkgs.jq
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            backup_timestamp="$(
              pgbackrest-secure --stanza=default --output=json info \
                | jq --exit-status --raw-output \
                  '.[0] | select(.status.code == 0) | [.backup[].timestamp.stop] | max'
            )"

            test "$backup_timestamp" -gt 0
            install -d -o root -g root -m 0755 ${metricsDirectory}

            temporary_file=${metricsDirectory}/pgbackrest-backup.prom.$$
            printf '%s\n' \
              '# HELP dsqr_pgbackrest_backup_last_success_timestamp_seconds Unix timestamp of the most recent successful pgBackRest backup.' \
              '# TYPE dsqr_pgbackrest_backup_last_success_timestamp_seconds gauge' \
              "dsqr_pgbackrest_backup_last_success_timestamp_seconds{stanza=\"default\"} $backup_timestamp" \
              > "$temporary_file"
            chmod 0644 "$temporary_file"
            mv "$temporary_file" ${metricsDirectory}/pgbackrest-backup.prom
          '';
        };

        systemd.timers.pgbackrest-backup-metrics = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5m";
            OnUnitActiveSec = "5m";
            Persistent = true;
          };
        };

        environment.systemPackages = [ pgBackRest ];
      };
    };
}
