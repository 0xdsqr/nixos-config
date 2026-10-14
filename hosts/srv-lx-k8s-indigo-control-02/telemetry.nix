{ config, lib, ... }:
let
  certificate = config.dsqr.nixos.vaultCertificates.host-telemetry;
in
{
  # Per-host enrollment; uses the worker-04-validated telemetry configuration.
  allowedUnfreePackageNames = [ "vault-bin" ];
  networking.hosts."10.10.30.102" = [ "beacon-telemetry.service.home.arpa" ];

  # A static supplemental group works even before Alloy's DynamicUser exists.
  users.groups.telemetry-client = { };
  systemd.services.alloy.serviceConfig.SupplementaryGroups = lib.mkAfter [ "telemetry-client" ];

  dsqr.nixos.vaultCertificates.host-telemetry = {
    roleId = "44fbbfb3-50ec-20ab-4efc-ea9166a4aa31";
    secretIdAgeFile = ./telemetry-pki.secret-id.age;
    issuePath = "pki_int/issue/indigo-control-02-telemetry-client";
    commonName = "srv-lx-k8s-indigo-control-02.telemetry-client.home.arpa";
    ttl = "720h";
    owner = "root";
    group = "telemetry-client";
    privateKeyMode = "0640";
    reloadUnit = "alloy.service";
    # Guaranteed reread on rotation; retain Alloy's existing state/positions.
    reloadAction = "try-restart";
  };

  dsqr.nixos.alloy = {
    remoteWriteUrl = "https://beacon-telemetry.service.home.arpa:9443/api/v1/write";
    clientTls = { inherit (certificate) certificateFile privateKeyFile; };
    hostCluster = "indigo";
    systemdUnitInclude = "(alloy|containerd|kubelet|tailscaled|vault-agent-.+)\\.service";
    remoteWriteMaxSampleAge = "15m";
    loki = {
      writeUrl = "https://beacon-telemetry.service.home.arpa:9443/loki/api/v1/push";
      journalMaxAge = "15m";
    };
  };
}
