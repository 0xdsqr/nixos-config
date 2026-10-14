_: {
  allowedUnfreePackageNames = [ "vault-bin" ];

  # Dedicated telemetry identity; existing collectors are not switched here.
  # Existing listeners and Grafana keep their current certificates and ports.
  dsqr.nixos.vaultCertificates.beacon-telemetry = {
    roleId = "73edab17-80c2-9d58-17fc-082b7da898b7";
    secretIdAgeFile = ./telemetry-pki.secret-id.age;
    issuePath = "pki_int/issue/beacon-telemetry-listener";
    commonName = "beacon-telemetry.service.home.arpa";
    ttl = "720h";
    owner = "root";
    group = "caddy";
    privateKeyMode = "0640";
    # NixOS's Caddy reload uses --force to reread renewed certificate files.
    reloadUnit = "caddy.service";
  };
}
