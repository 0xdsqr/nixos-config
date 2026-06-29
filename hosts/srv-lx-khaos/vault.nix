{ pkgs, ... }:
let
  apiAddr = "https://vault.home.arpa";
  auditLog = "/var/log/vault/audit.log";
in
{
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
