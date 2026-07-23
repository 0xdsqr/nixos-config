_: {
  dsqr.nixos.postgresql = {
    listenAddresses = [
      "127.0.0.1"
      "::1"
      "10.10.30.109"
    ];

    allowedCIDRs = [ ];

    hostAuthenticationRules = [
      {
        type = "hostssl";
        database = "grafana";
        user = "grafana";
        address = "10.10.30.102/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "dsqr-dotdev";
        user = "dsqr-dotdev";
        address = "10.10.30.103/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "fidara";
        user = "fidara";
        address = "10.10.30.103/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "tastingswithtay";
        address = "10.10.30.103/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "dsqr-dotdev";
        user = "dsqr-dotdev";
        address = "10.10.30.105/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "fidara";
        user = "fidara";
        address = "10.10.30.105/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "tastingswithtay";
        address = "10.10.30.105/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "temporal,temporal_visibility";
        user = "temporal";
        address = "10.10.30.107/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "replication";
        user = "knox_replication";
        address = "10.10.30.107/32";
        method = "scram-sha-256";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
}
