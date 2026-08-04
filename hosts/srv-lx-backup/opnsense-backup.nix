{ config, pkgs, ... }:
let
  credentials = config.age.secrets.opnsenseBackupApi.path;
  keys = import ../../profiles/dsqr/keys.nix;
  metricsDirectory = "/var/lib/alloy/textfile";
  repository = "/var/lib/backup/system-config/opnsense";

  originCa = pkgs.fetchurl {
    url = "https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem";
    hash = "sha256-kailVn76a/lBFiqoBrO6R2qt33hnZA5TBTs1+yJaXa4=";
  };
in
{
  age.secrets.opnsenseBackupApi = {
    file = ./opnsense-api.age;
    mode = "0400";
  };

  systemd.tmpfiles.rules = [ "d ${repository} 0700 root root - -" ];

  systemd.services.opnsense-config-backup = {
    description = "Back up OPNsense configuration";
    after = [
      "network-online.target"
      "pgbackrest-repository-mount.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "pgbackrest-repository-mount.service" ];
    path = [
      pkgs.age
      pkgs.coreutils
      pkgs.curl
      pkgs.findutils
      pkgs.libxml2
    ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      LoadCredential = "api:${credentials}";
      CapabilityBoundingSet = "";
      IPAddressAllow = "10.10.10.1/32";
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
    script = /* bash */ ''
      source "$CREDENTIALS_DIRECTORY/api"

      test -n "''${key:-}"
      test -n "''${secret:-}"

      netrc="$(mktemp)"
      timestamp="$(date --utc +%Y%m%dT%H%M%SZ)"
      plaintext_file="${repository}/.$timestamp.xml"
      encrypted_file="${repository}/.$timestamp.xml.age.tmp"
      trap 'rm -f "$netrc" "$plaintext_file" "$encrypted_file"' EXIT

      printf 'machine opnsense.dsqr.dev login %s password %s\n' "$key" "$secret" > "$netrc"
      unset key secret

      curl \
        --cacert ${originCa} \
        --connect-timeout 10 \
        --fail-with-body \
        --max-time 60 \
        --netrc-file "$netrc" \
        --output "$plaintext_file" \
        --proto '=https' \
        --resolve opnsense.dsqr.dev:443:10.10.10.1 \
        --retry 3 \
        --retry-all-errors \
        --retry-delay 2 \
        --show-error \
        --silent \
        --tlsv1.2 \
        https://opnsense.dsqr.dev/api/core/backup/download/this

      test "$(xmllint --xpath 'name(/*)' "$plaintext_file")" = opnsense

      age \
        --encrypt \
        --output "$encrypted_file" \
        --recipient ${builtins.toJSON keys.users.dsqr} \
        "$plaintext_file"

      final_file="${repository}/$timestamp.xml.age"
      chmod 0600 "$encrypted_file"
      mv "$encrypted_file" "$final_file"
      rm -f "$plaintext_file"
      find ${repository} -type f -name '*.xml.age' -mtime +31 -delete

      temporary_metric=${metricsDirectory}/config-backup-opnsense.prom.$$
      printf '%s\n' \
        '# HELP dsqr_config_backup_last_success_timestamp_seconds Unix timestamp of the most recent successful configuration backup.' \
        '# TYPE dsqr_config_backup_last_success_timestamp_seconds gauge' \
        "dsqr_config_backup_last_success_timestamp_seconds{source=\"opnsense\"} $(date +%s)" \
        > "$temporary_metric"
      chmod 0644 "$temporary_metric"
      mv "$temporary_metric" ${metricsDirectory}/config-backup-opnsense.prom
    '';
  };

  systemd.timers.opnsense-config-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:45:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
