_: {
  dsqr.nixos.postgresql = {
    listenAddresses = [
      "127.0.0.1"
      "::1"
      "10.10.30.109"
    ];

    allowedCIDRs = [
      "127.0.0.1/32"
      "::1/128"
      "10.10.30.102/32"
      "10.10.30.103/32"
      "10.10.30.105/32"
      "10.10.30.107/32"
    ];

    hostAuthMethod = "scram-sha-256";
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
}
