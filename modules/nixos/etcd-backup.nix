{
  flake.nixosModules.etcd-backup =
    { config, lib, pkgs, ... }:
    let
      inherit (lib) mkEnableOption mkOption mkIf mkMerge escapeShellArg;
      inherit (lib.types) attrsOf ints listOf str submodule;
      cfg = config.dsqr.nixos.etcdBackup;
      nameType = lib.types.strMatching "[a-z0-9][a-z0-9-]*";
      addressType = lib.types.strMatching "([0-9]{1,3}\\.){3}[0-9]{1,3}";
      metricsDirectory = "/var/lib/alloy/textfile";
      rootDirectory = "/var/lib/backup/etcd";
      criConfig = pkgs.writeText "etcd-backup-crictl.yaml" ''
        runtime-endpoint: unix:///run/containerd/containerd.sock
        image-endpoint: unix:///run/containerd/containerd.sock
        timeout: 10
      '';
      recipients = pkgs.writeText "etcd-backup-recipients" (lib.concatStringsSep "\n" cfg.source.recoveryRecipients + "\n");
      snapshotWorker = pkgs.writeShellApplication {
        name = "dsqr-etcd-snapshot-worker";
        runtimeInputs = [ pkgs.coreutils pkgs.util-linux pkgs.gnutar pkgs.gzip pkgs.age pkgs.jq config.dsqr.nixos.kubeadm.packages.criTools ];
        text = ''
          export ETCD_DATA_DIRECTORY=/var/lib/etcd
          export ETCD_BACKUP_LOCK=/run/lock/dsqr-etcd-snapshot.lock
          export CRICTL_CONFIG=${criConfig}
          export AGE_RECIPIENTS_FILE=${recipients}
          export ETCD_CLUSTER_NAME=${escapeShellArg cfg.source.clusterName}
          ${builtins.readFile ./etcd-backup/export.sh}
        '';
      };
      exporter = pkgs.writeShellApplication {
        name = "dsqr-etcd-snapshot-export";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          if (( $# != 0 )); then
            echo 'The snapshot exporter does not accept arguments.' >&2
            exit 1
          fi
          exec timeout --kill-after=30s 10m ${lib.getExe snapshotWorker}
        '';
      };
      authorizedCommand = pkgs.writeShellApplication {
        name = "dsqr-etcd-snapshot-authorized";
        text = ''
          if [[ "''${SSH_ORIGINAL_COMMAND:-}" != export-etcd-snapshot-v1 ]]; then
            echo 'Only the encrypted etcd snapshot export command is allowed.' >&2
            exit 1
          fi
          exec /run/wrappers/bin/sudo -n ${lib.getExe exporter}
        '';
      };
      collector = name: job:
        let
          knownHosts = pkgs.writeText "etcd-backup-${name}-known-hosts" "${job.sourceAddress} ${job.sourceHostPublicKey}\n";
        in
        pkgs.writeShellApplication {
          name = "dsqr-etcd-backup-${name}";
          runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.openssh pkgs.util-linux ];
          text = ''
            export BACKUP_MOUNT=/var/lib/backup
            export BACKUP_DIRECTORY=${escapeShellArg "${rootDirectory}/${name}"}
            export BACKUP_SOURCE=${escapeShellArg job.sourceAddress}
            export BACKUP_KNOWN_HOSTS=${knownHosts}
            export BACKUP_RETENTION_DAYS=${toString job.retentionDays}
            export BACKUP_METRICS_DIRECTORY=${metricsDirectory}
            export ETCD_CLUSTER_NAME=${escapeShellArg name}
            ${builtins.readFile ./etcd-backup/collect.sh}
          '';
        };
    in
    {
      options.dsqr.nixos.etcdBackup = {
        source = {
          enable = mkEnableOption "restricted encrypted snapshot export from a kubeadm stacked-etcd member";
          clusterName = mkOption { type = nameType; default = "kubernetes"; };
          collectorAddress = mkOption { type = addressType; default = "127.0.0.1"; description = "Only this source IP may use the export SSH key."; };
          collectorPublicKey = mkOption { type = str; default = ""; };
          recoveryRecipients = mkOption { type = listOf str; default = [ ]; description = "Public age/SSH recovery recipients; no private recovery key is installed on the collector."; };
        };
        collector = {
          enable = mkEnableOption "scheduled encrypted etcd snapshot collection on the backup VM";
          jobs = mkOption {
            default = { };
            type = attrsOf (submodule {
              options = {
                sourceAddress = mkOption { type = addressType; };
                sourceHostPublicKey = mkOption { type = str; };
                onCalendar = mkOption { type = str; default = "*-*-* 00,06,12,18:00:00"; };
                retentionDays = mkOption { type = ints.positive; default = 31; };
              };
            });
          };
        };
      };

      config = mkMerge [
        (mkIf cfg.source.enable {
          assertions = [
            { assertion = config.dsqr.nixos.kubeadm.enable && config.dsqr.nixos.kubeadm.role == "control-plane"; message = "etcd snapshot export requires a kubeadm control-plane node."; }
            { assertion = cfg.source.clusterName == config.dsqr.nixos.kubeadm.cluster.name; message = "etcd snapshot labels must match the source node's cluster."; }
            { assertion = cfg.source.collectorPublicKey != "" && cfg.source.recoveryRecipients != [ ]; message = "etcd snapshot export requires a collector key and independent recovery recipients."; }
          ];
          users.groups.etcd-snapshot = { };
          users.users.etcd-snapshot = {
            isSystemUser = true;
            group = "etcd-snapshot";
            home = "/var/empty";
            shell = pkgs.bashInteractive;
            openssh.authorizedKeys.keys = [
              ''restrict,from="${cfg.source.collectorAddress}/32",command="${lib.getExe authorizedCommand}" ${cfg.source.collectorPublicKey}''
            ];
          };
          security.sudo.extraRules = [{
            users = [ "etcd-snapshot" ];
            commands = [{ command = ''${lib.getExe exporter} ""''; options = [ "NOPASSWD" ]; }];
          }];
        })
        (mkIf cfg.collector.enable {
          assertions = [{
            assertion = cfg.collector.jobs != { } && lib.all (name: builtins.match "[a-z0-9][a-z0-9-]*" name != null) (builtins.attrNames cfg.collector.jobs);
            message = "etcd collectors require named jobs using lowercase letters, digits and hyphens.";
          }];
          systemd.tmpfiles.rules = [
            "d ${rootDirectory} 0700 root root -"
            "d ${metricsDirectory} 0755 root root -"
          ] ++ lib.mapAttrsToList (name: _: "d ${rootDirectory}/${name} 0700 root root -") cfg.collector.jobs;
          systemd.services = (lib.mapAttrs' (name: job: lib.nameValuePair "etcd-backup-${name}" {
            description = "Collect a validated encrypted ${name} etcd snapshot";
            after = [ "network-online.target" "tailscaled.service" "var-lib-backup.mount" "etcd-backup-metrics.service" ];
            wants = [ "network-online.target" ];
            requires = [ "var-lib-backup.mount" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = lib.getExe (collector name job);
              TimeoutStartSec = "15min";
              UMask = "0077";
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              PrivateDevices = true;
              NoNewPrivileges = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectKernelLogs = true;
              ProtectControlGroups = true;
              ProtectClock = true;
              ProtectHostname = true;
              LockPersonality = true;
              RestrictSUIDSGID = true;
              RestrictRealtime = true;
              RestrictNamespaces = true;
              MemoryDenyWriteExecute = true;
              CapabilityBoundingSet = "";
              RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
              IPAddressDeny = "any";
              IPAddressAllow = "${job.sourceAddress}/32";
              ReadWritePaths = [ "${rootDirectory}/${name}" metricsDirectory ];
            };
          }) cfg.collector.jobs) // {
            etcd-backup-metrics = {
              description = "Initialize etcd backup freshness metrics without claiming success";
              wantedBy = [ "multi-user.target" ];
              before = [ "alloy.service" ];
              serviceConfig.Type = "oneshot";
              script = ''
                ${pkgs.coreutils}/bin/install -d -o root -g root -m 0755 ${metricsDirectory}
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _: ''
                  if [[ ! -e ${metricsDirectory}/etcd-${name}.prom ]]; then
                    printf '%s\n' 'dsqr_etcd_backup_last_success_timestamp_seconds{cluster="${name}"} 0' > ${metricsDirectory}/etcd-${name}.prom
                    ${pkgs.coreutils}/bin/chmod 0644 ${metricsDirectory}/etcd-${name}.prom
                  fi
                '') cfg.collector.jobs)}
              '';
            };
          };
          systemd.timers = lib.mapAttrs' (name: job: lib.nameValuePair "etcd-backup-${name}" {
            wantedBy = [ "timers.target" ];
            timerConfig = { OnCalendar = job.onCalendar; Persistent = true; RandomizedDelaySec = "10min"; };
          }) cfg.collector.jobs;
        })
      ];
    };
}
