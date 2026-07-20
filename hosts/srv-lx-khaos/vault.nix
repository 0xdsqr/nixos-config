{
  config,
  lib,
  pkgs,
  ...
}:
let
  apiAddr = "https://vault.home.arpa";
  auditLog = "/var/log/vault/audit.log";
  listenerCertificate = {
    authPath = "auth/approle/login";
    caFile = "/etc/ssl/certs/ca-certificates.crt";
    certificateDirectory = "/var/lib/vault/tls";
    certificateFile = "/var/lib/vault/tls/fullchain.pem";
    commonName = "vault.service.home.arpa";
    environmentFile = config.age.secrets.vaultListenerPki.path;
    issuePath = "pki_int/issue/vault-listener";
    keyFile = "/var/lib/vault/tls/key.pem";
    renewBeforeSeconds = 7 * 24 * 60 * 60;
    ttl = "720h";
    # Bootstrap only: Phase 2D.2 replaces this after the first listener certificate exists.
    vaultAddr = "http://127.0.0.1:8200";
  };
  renewListenerCertificate = pkgs.writeShellApplication {
    name = "vault-renew-listener-certificate";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      pkgs.openssl
    ];
    text = ''
      set -euo pipefail
      umask 0077

      vault_addr='${listenerCertificate.vaultAddr}'
      auth_path='${listenerCertificate.authPath}'
      ca_file='${listenerCertificate.caFile}'
      issue_path='${listenerCertificate.issuePath}'
      env_file='${listenerCertificate.environmentFile}'
      cert_dir='${listenerCertificate.certificateDirectory}'
      cert_file='${listenerCertificate.certificateFile}'
      key_file='${listenerCertificate.keyFile}'
      common_name='${listenerCertificate.commonName}'
      ttl='${listenerCertificate.ttl}'
      renew_before_seconds='${toString listenerCertificate.renewBeforeSeconds}'

      certificate_matches_key() {
        local cert_public_key private_public_key
        cert_public_key="$(openssl x509 -in "$1" -pubkey -noout | openssl sha256)"
        private_public_key="$(openssl pkey -in "$2" -pubout | openssl sha256)"
        [ "$cert_public_key" = "$private_public_key" ]
      }

      if [ -s "$cert_file" ] && [ -s "$key_file" ] \
        && openssl x509 -checkend "$renew_before_seconds" -noout -in "$cert_file" >/dev/null \
        && openssl x509 -checkhost "$common_name" -noout -in "$cert_file" >/dev/null \
        && certificate_matches_key "$cert_file" "$key_file"; then
        echo "Vault listener certificate is still valid."
        exit 0
      fi

      if [ ! -r "$env_file" ]; then
        echo "Missing readable Vault AppRole environment file: $env_file" >&2
        exit 1
      fi

      # shellcheck source=/dev/null
      . "$env_file"

      : "''${VAULT_ROLE_ID:?VAULT_ROLE_ID is required in $env_file}"
      : "''${VAULT_SECRET_ID:?VAULT_SECRET_ID is required in $env_file}"

      install -d -o vault -g vault -m 0750 "$cert_dir"
      work_dir="$(mktemp -d "$cert_dir/.renew.XXXXXX")"
      cleanup() {
        rm -rf "$work_dir"
      }
      trap cleanup EXIT

      login_payload="$(
        printf '%s\n%s\n' "$VAULT_ROLE_ID" "$VAULT_SECRET_ID" \
          | jq -Rsc 'split("\n") | { role_id: .[0], secret_id: .[1] }'
      )"
      token="$(
        printf '%s' "$login_payload" \
          | curl --fail --silent --show-error \
          --connect-timeout 5 \
          --max-time 30 \
          --retry 2 \
          --retry-connrefused \
          --request POST \
          --header 'Content-Type: application/json' \
          --data-binary @- \
          "$vault_addr/v1/$auth_path" \
          | jq -er '.auth.client_token'
      )"
      token_header_file="$work_dir/token-header"
      printf 'X-Vault-Token: %s\n' "$token" > "$token_header_file"
      chmod 0600 "$token_header_file"

      issue_payload="$(
        jq -nc \
          --arg common_name "$common_name" \
          --arg ttl "$ttl" \
          '{ common_name: $common_name, ttl: $ttl }'
      )"
      issue_response="$(
        printf '%s' "$issue_payload" \
          | curl --fail --silent --show-error \
          --connect-timeout 5 \
          --max-time 30 \
          --retry 2 \
          --retry-connrefused \
          --request POST \
          --header @"$token_header_file" \
          --header 'Content-Type: application/json' \
          --data-binary @- \
          "$vault_addr/v1/$issue_path"
      )"

      printf '%s' "$issue_response" | jq -er '.data.private_key' > "$work_dir/key.pem"
      printf '%s' "$issue_response" | jq -er '.data.certificate' > "$work_dir/certificate.pem"
      printf '%s' "$issue_response" | jq -er '.data.issuing_ca' > "$work_dir/issuing-ca.pem"
      cat "$work_dir/certificate.pem" "$work_dir/issuing-ca.pem" > "$work_dir/fullchain.pem"

      chmod 0600 "$work_dir/key.pem"
      chmod 0644 "$work_dir/fullchain.pem"
      openssl x509 -checkhost "$common_name" -noout -in "$work_dir/fullchain.pem"
      openssl verify \
        -CAfile "$ca_file" \
        -untrusted "$work_dir/issuing-ca.pem" \
        "$work_dir/certificate.pem"
      if ! certificate_matches_key "$work_dir/fullchain.pem" "$work_dir/key.pem"; then
        echo "Issued Vault listener certificate does not match its private key." >&2
        exit 1
      fi

      install -o vault -g vault -m 0600 "$work_dir/key.pem" "$key_file"
      install -o vault -g vault -m 0644 "$work_dir/fullchain.pem" "$cert_file"
      echo "Renewed Vault listener certificate for $common_name."
    '';
  };
in
{
  age.secrets.vaultListenerPki = {
    file = ./vault-listener-pki.env.age;
    owner = "vault";
    group = "vault";
    mode = "0400";
  };

  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "raft";
    listenerExtraConfig = ''
      tls_min_version = "tls12"
      redact_addresses = true
      redact_cluster_name = true
      redact_version = true
      custom_response_headers {
        "default" = {
          "Strict-Transport-Security" = ["max-age=31536000", "includeSubDomains"]
        }
      }
    '';
    extraConfig = ''
      ui = true
      api_addr = "${apiAddr}"
      cluster_addr = "http://10.10.30.107:8201"
      disable_mlock = true
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8200 ];

  environment.systemPackages = [ pkgs.vault-bin ];
  environment.variables.VAULT_ADDR = apiAddr;

  systemd.tmpfiles.rules = [
    "d /var/log/vault 0750 vault vault - -"
    "d ${listenerCertificate.certificateDirectory} 0750 vault vault - -"
  ];

  systemd.services.vault-listener-certificate = {
    description = "Renew the Vault listener certificate from Vault PKI";
    after = [ "vault.service" ];
    requires = [ "vault.service" ];
    unitConfig.ConditionPathExists = listenerCertificate.environmentFile;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe renewListenerCertificate;
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ listenerCertificate.certificateDirectory ];
    };
  };

  systemd.timers.vault-listener-certificate = {
    description = "Daily Vault listener certificate renewal check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
      Unit = "vault-listener-certificate.service";
    };
  };

  services.logrotate = {
    enable = true;
    settings.${auditLog} = {
      frequency = "daily";
      rotate = 14;
      compress = true;
      missingok = true;
      notifempty = true;
      create = "0600 vault vault";
      postrotate = ''
        systemctl kill -s HUP vault.service || true
      '';
    };
  };
}
