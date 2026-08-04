{
  flake.nixosModules.postgresql-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkForce mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) path str;

      cfg = config.dsqr.nixos.backup.postgresql;
      repositoryEnvironment = config.age.secrets."pgbackrest-repository-environment".path;
      repositoryKey = config.age.secrets."pgbackrest-repository-key".path;
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
      repositorySsh = pkgs.writeShellApplication {
        name = "pgbackrest-ssh";
        runtimeInputs = [ pkgs.openssh ];
        text = ''
          exec ssh \
            -o IdentitiesOnly=yes \
            -i ${repositoryKey} \
            "$@"
        '';
      };
      jobNames = [
        "full"
        "differential"
        "incremental"
      ];
    in
    {
      options.dsqr.nixos.backup.postgresql = {
        enable = mkEnableOption "PostgreSQL point-in-time recovery with pgBackRest";

        repositoryHost = mkOption {
          type = str;
          default = "10.10.30.111";
          description = "Dedicated pgBackRest repository host.";
        };

        repositoryPath = mkOption {
          type = str;
          default = "/var/lib/backup/postgresql";
          description = "Repository path on the backup host.";
        };

        repositoryHostPublicKey = mkOption {
          type = str;
          description = "Pinned SSH host public key for the repository host.";
        };

        repositorySshPrivateKeyAgeFile = mkOption {
          type = path;
          description = "Encrypted dedicated SSH private key for the pgBackRest remote protocol.";
        };

        repositoryEnvironmentAgeFile = mkOption {
          type = path;
          description = "Encrypted environment file containing the repository cipher passphrase.";
        };

        schedules = {
          full = mkOption {
            type = str;
            default = "Sun *-*-* 01:00:00";
            description = "Full backup schedule.";
          };

          differential = mkOption {
            type = str;
            default = "Mon..Sat *-*-* 01:00:00";
            description = "Differential backup schedule.";
          };

          incremental = mkOption {
            type = str;
            default = "*-*-* 05,11,17,23:00:00";
            description = "Incremental backup schedule.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = config.services.postgresql.enable;
            message = "PostgreSQL backups require services.postgresql.enable.";
          }
        ];

        age.secrets = {
          "pgbackrest-repository-environment" = {
            file = cfg.repositoryEnvironmentAgeFile;
            owner = "root";
            group = "pgbackrest";
            mode = "0440";
          };

          "pgbackrest-repository-key" = {
            file = cfg.repositorySshPrivateKeyAgeFile;
            owner = "root";
            group = "pgbackrest";
            mode = "0440";
          };
        };

        programs.ssh.knownHosts.pgbackrest-repository = {
          hostNames = [ cfg.repositoryHost ];
          publicKey = cfg.repositoryHostPublicKey;
        };

        services.pgbackrest = {
          enable = true;

          repos.${cfg.repositoryHost} = {
            path = cfg.repositoryPath;
            host-user = "pgbackrest";
            host-cmd = getExe pgBackRest;
            bundle = true;
            block = true;
            cipher-type = "aes-256-cbc";
            retention-full = 2;
            retention-diff = 14;
            retention-archive-type = "full";
          };

          settings = {
            process-max = 2;
            cmd-ssh = mkForce (getExe repositorySsh);
            archive-async = true;
            archive-timeout = 60;
            spool-path = "/var/spool/pgbackrest";
            lock-path = "/var/spool/pgbackrest";
            compress-type = "zst";
            compress-level = 3;
          };

          stanzas.default = {
            settings.cmd = mkForce (getExe pgBackRest);
            jobs = {
              full = {
                schedule = cfg.schedules.full;
                type = "full";
              };
              differential = {
                schedule = cfg.schedules.differential;
                type = "diff";
              };
              incremental = {
                schedule = cfg.schedules.incremental;
                type = "incr";
              };
            };
          };
        };

        services.postgresql.settings = {
          archive_mode = mkForce "on";
          archive_command = mkForce ''${getExe pgBackRest} --stanza=default archive-push "%p"'';
          archive_timeout = mkForce 60;
        };

        systemd.services = {
          postgresql.serviceConfig.ReadWritePaths = [ "/var/spool/pgbackrest" ];
        }
        // builtins.listToAttrs (
          map (name: {
            name = "pgbackrest-default-${name}";
            value.serviceConfig = {
              EnvironmentFile = repositoryEnvironment;
              User = mkForce "postgres";
              Group = mkForce "postgres";
            };
          }) jobNames
        );

        systemd.tmpfiles.rules = [ "d /var/spool/pgbackrest 0750 postgres postgres -" ];

        environment.systemPackages = [ pgBackRest ];
      };
    };
}
