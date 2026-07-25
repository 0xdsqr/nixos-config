{ pkgs, ... }:
let
  apiAddr = "https://vault.home.arpa";
  auditLog = "/var/log/vault/audit.log";
  listenerCertificate = {
    directory = "/var/lib/vault/tls";
    certificateFile = "/var/lib/vault/tls/fullchain.pem";
    commonName = "vault.service.home.arpa";
    issuePath = "pki_int/issue/vault-listener";
    privateKeyFile = "/var/lib/vault/tls/key.pem";
  };
in
{
  dsqr.nixos.vaultCertificates.vaultListener = {
    roleId = "1b2715fa-ae7b-e4f0-41b3-e739e52f0e79";
    secretIdAgeFile = ./vault-listener-pki.secret-id.age;
    inherit (listenerCertificate)
      certificateFile
      commonName
      directory
      issuePath
      privateKeyFile
      ;
    owner = "vault";
    group = "vault";
    reloadUnit = "vault.service";
    requireCertificateForUnitStart = false;
  };

  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    tlsCertFile = listenerCertificate.certificateFile;
    tlsKeyFile = listenerCertificate.privateKeyFile;
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
      cluster_addr = "https://vault.service.home.arpa:8201"
      disable_mlock = true
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8200 ];

  environment.systemPackages = [ pkgs.vault-bin ];
  environment.variables.VAULT_ADDR = apiAddr;

  systemd.tmpfiles.rules = [ "d /var/log/vault 0750 vault vault - -" ];

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
