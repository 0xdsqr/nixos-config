{
  flake.nixosModules.restic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) elem;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatMapStringsSep escapeShellArg;
      inherit (lib.types)
        listOf
        nullOr
        package
        path
        str
        ;

      cfg = config.dsqr.nixos.restic;
      isReceiver = elem config.networking.hostName cfg.receiverHosts;
      hasPasswordAgeFile = cfg.passwordAgeFile != null && builtins.pathExists cfg.passwordAgeFile;
      backupHosts = config.services.restic.hosts;
      metricsDirectory = "/var/lib/alloy/textfile";
      metricsFile = host: "${metricsDirectory}/restic-${host}.prom";
      initializeMetrics = concatMapStringsSep "\n" (
        host:
        let
          file = metricsFile host;
        in
        ''
          if [[ ! -e ${escapeShellArg file} ]]; then
            printf '%s\n' \
              '# HELP dsqr_restic_backup_last_success_timestamp_seconds Unix timestamp of the most recent successful restic backup.' \
              '# TYPE dsqr_restic_backup_last_success_timestamp_seconds gauge' \
              'dsqr_restic_backup_last_success_timestamp_seconds{repository_host="${host}"} 0' \
              > ${escapeShellArg file}
            chmod 0644 ${escapeShellArg file}
          fi
        ''
      ) backupHosts;
    in
    {
      options = {
        dsqr.nixos.restic = {
          enable = mkEnableOption "Enable the shared restic backup baseline";

          hosts = mkOption {
            type = listOf str;
            default = [ ];
            description = "Hosts that receive this machine's restic backups.";
          };

          receiverHosts = mkOption {
            type = listOf str;
            default = [ ];
            description = "Hosts that receive restic backups over SSH.";
          };

          authorizedKeys = mkOption {
            type = listOf str;
            default = [ ];
            description = "SSH public keys authorized to push restic backups to receiver hosts.";
          };

          package = mkOption {
            type = package;
            default = pkgs.restic;
            defaultText = "pkgs.restic";
            description = "restic package to install.";
          };

          passwordAgeFile = mkOption {
            type = nullOr path;
            default = null;
            description = "Encrypted age file that stores the restic repository password.";
          };
        };

        services.restic.hosts = mkOption {
          type = listOf str;
          default = cfg.hosts;
          description = "Computed list of hosts that receive this machine's restic backups.";
        };
      };

      config = mkIf cfg.enable (
        mkIf isReceiver {
          users.users.backup = {
            description = "Backup";
            isNormalUser = true;
            openssh.authorizedKeys.keys = cfg.authorizedKeys;
          };
        }
        // mkIf (config.services.restic.hosts != [ ] && hasPasswordAgeFile) {
          age.secrets.resticPassword.file = cfg.passwordAgeFile;

          environment.systemPackages = [ cfg.package ];

          services.restic.backups = genAttrs config.services.restic.hosts (host: {
            repository = "sftp:backup@${host}:${config.networking.hostName}-backup";
            passwordFile = config.age.secrets.resticPassword.path;
            initialize = true;
            extraOptions = [
              "sftp.command='ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=accept-new backup@${host} -s sftp'"
            ];

            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
            ];
          });

          systemd.services =
            genAttrs (map (host: "restic-backups-${host}") backupHosts) (
              unitName:
              let
                host = builtins.replaceStrings [ "restic-backups-" ] [ "" ] unitName;
                file = metricsFile host;
              in
              {
                postStart = ''
                  temporary_file=${escapeShellArg file}.$$
                  printf '%s\n' \
                    '# HELP dsqr_restic_backup_last_success_timestamp_seconds Unix timestamp of the most recent successful restic backup.' \
                    '# TYPE dsqr_restic_backup_last_success_timestamp_seconds gauge' \
                    "dsqr_restic_backup_last_success_timestamp_seconds{repository_host=\"${host}\"} $(${pkgs.coreutils}/bin/date +%s)" \
                    > "$temporary_file"
                  chmod 0644 "$temporary_file"
                  mv "$temporary_file" ${escapeShellArg file}
                '';
              }
            )
            // {
              restic-backup-metrics = {
                description = "Initialize restic backup health metrics";
                wantedBy = [ "multi-user.target" ];
                before = [ "alloy.service" ];
                serviceConfig.Type = "oneshot";
                script = ''
                  install -d -o root -g root -m 0755 ${metricsDirectory}
                  ${initializeMetrics}
                '';
              };
            };
        }
      );
    };
}
