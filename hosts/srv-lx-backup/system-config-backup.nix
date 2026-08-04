{ pkgs, ... }:
let
  keys = import ../../profiles/dsqr/keys.nix;
  metricsDirectory = "/var/lib/alloy/textfile";
  repository = "/var/lib/backup/system-config/proxmox";
  target = "100.125.141.48";
in
{
  programs.ssh.knownHosts.proxmox = {
    hostNames = [ target ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUG4TX9b5LNthwzHg7CYSWibGNjh3bH2hOo+OSrVoRD";
  };

  systemd.services.proxmox-config-backup = {
    description = "Back up Proxmox configuration";
    after = [
      "network-online.target"
      "var-lib-backup.mount"
    ];
    wants = [ "network-online.target" ];
    requires = [ "var-lib-backup.mount" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      CapabilityBoundingSet = "";
      IPAddressAllow = "${target}/32";
      IPAddressDeny = "any";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        metricsDirectory
        repository
      ];
      RestrictAddressFamilies = [ "AF_INET" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
    };
    path = [
      pkgs.age
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnutar
      pkgs.gzip
      pkgs.openssh
    ];
    postStart = ''
      install -d -o root -g root -m 0755 ${metricsDirectory}
      temporary_metric=${metricsDirectory}/config-backup-proxmox.prom.$$
      printf '%s\n' \
        '# HELP dsqr_config_backup_last_success_timestamp_seconds Unix timestamp of the most recent successful configuration backup.' \
        '# TYPE dsqr_config_backup_last_success_timestamp_seconds gauge' \
        "dsqr_config_backup_last_success_timestamp_seconds{source=\"proxmox\"} $(date +%s)" \
        > "$temporary_metric"
      chmod 0644 "$temporary_metric"
      mv "$temporary_metric" ${metricsDirectory}/config-backup-proxmox.prom
    '';
    script = ''
      install -d -o root -g root -m 0700 ${repository}

      timestamp="$(date --utc +%Y%m%dT%H%M%SZ)"
      plaintext_file="${repository}/.''${timestamp}.tar.gz"
      encrypted_file="${repository}/.''${timestamp}.tar.gz.age.tmp"
      trap 'rm -f "$plaintext_file" "$encrypted_file"' EXIT

      ssh \
        -i /etc/ssh/ssh_host_ed25519_key \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=yes \
        root@${target} \
        > "$plaintext_file"

      test -s "$plaintext_file"
      tar --gzip --list --file "$plaintext_file" >/dev/null

      age \
        --encrypt \
        --output "$encrypted_file" \
        --recipient ${builtins.toJSON keys.users.dsqr} \
        "$plaintext_file"

      final_file="${repository}/$timestamp.tar.gz.age"
      chmod 0600 "$encrypted_file"
      mv "$encrypted_file" "$final_file"
      rm -f "$plaintext_file"

      find ${repository} -type f -name '*.tar.gz.age' -mtime +31 -delete
      find ${repository} -type f \( -name '*.tar.gz' -o -name '*.tmp' \) -delete
    '';
  };

  systemd.timers.proxmox-config-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:15:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
