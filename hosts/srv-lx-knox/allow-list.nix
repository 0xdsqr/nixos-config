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
        database = "dsqr-dotdev";
        user = "dotdev_runtime";
        address = "10.10.80.106/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "dsqr-dotdev";
        user = "dotdev_runtime";
        address = "10.10.80.107/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "dsqr-dotdev";
        user = "dotdev_runtime";
        address = "10.10.80.108/32";
        method = "scram-sha-256";
      }
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
      # Transitional Hub-A runtime identities. The legacy owner login remains
      # allowed until both live workloads have switched to these credentials.
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "twt_web_huba_runtime,twt_admin_huba_runtime";
        address = "10.10.30.103/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "twt_web_huba_runtime,twt_admin_huba_runtime";
        address = "10.10.30.105/32";
        method = "scram-sha-256";
      }
      # Indigo application workers. Each workload has an independently
      # revocable login while sharing the non-login runtime grant role.
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "twt_web_indigo_runtime,twt_admin_indigo_runtime";
        address = "10.10.80.106/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "twt_web_indigo_runtime,twt_admin_indigo_runtime";
        address = "10.10.80.107/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "tastingswithtay";
        user = "twt_web_indigo_runtime,twt_admin_indigo_runtime";
        address = "10.10.80.108/32";
        method = "scram-sha-256";
      }
      {
        type = "hostssl";
        database = "temporal,temporal_visibility";
        user = "temporal";
        address = "10.10.30.107/32";
        method = "scram-sha-256";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
}
