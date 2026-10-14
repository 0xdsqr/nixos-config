{ config, pkgs, ... }:
let
  certificate = config.dsqr.nixos.vaultCertificates.beacon-telemetry;
  listenerConfig =
    builtins.replaceStrings
      [
        "@ADMIN@"
        "@PORT@"
        "@BIND@"
        "@CERT@"
        "@KEY@"
        "@CLIENT_CA@"
        "@PROMETHEUS@"
        "@LOKI@"
        "@TEMPO@"
      ]
      [
        "unix//run/caddy/admin.sock"
        "9443"
        "10.10.30.102"
        certificate.certificateFile
        certificate.privateKeyFile
        (toString config.dsqr.security.certificates.homeRootCA.certificateFile)
        "127.0.0.1:9090"
        "127.0.0.1:3100"
        "10.10.30.102:4318"
      ]
      (builtins.readFile ./telemetry.Caddyfile);
in
{
  # This is a dedicated ingestion proxy, not the gateway's UI proxy baseline.
  services.caddy = {
    enable = true;
    enableReload = true;
    openFirewall = false;
    configFile = pkgs.writeText "beacon-telemetry.Caddyfile" listenerConfig;
    adapter = "caddyfile";
  };

  systemd.services.caddy.serviceConfig = {
    RuntimeDirectory = "caddy";
    RuntimeDirectoryMode = "0750";
    UMask = "0077";
  };

  # No subnet-wide allowance, HTTP listener, UDP/QUIC, or public-interface bind.
  # OPNsense's cross-VLAN rule must also explicitly allow this destination/port.
  networking.firewall.extraInputRules = ''
    ip saddr { 10.10.80.100, 10.10.80.101, 10.10.80.102, 10.10.80.103, 10.10.80.104, 10.10.80.105, 10.10.80.106, 10.10.80.107, 10.10.80.108 } ip daddr 10.10.30.102 tcp dport 9443 accept
  '';
}
