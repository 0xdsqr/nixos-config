{ config, lib, ... }:
let
  inherit (lib.attrsets) genAttrs;

  address = "10.10.30.102";
  port = 4040;
in
{
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Pyroscope";
      uid = "pyroscope";
      type = "grafana-pyroscope-datasource";
      access = "proxy";
      url = "http://${address}:${toString port}";
      jsonData.minStep = "15s";
    }
  ];

  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ "/var/lib/pyroscope" ];
  });

  services.pyroscope = {
    enable = true;
    settings = {
      target = "all";
      multitenancy_enabled = false;
      architecture_storage = "v2";
      show_banner = false;

      server = {
        http_listen_address = address;
        http_listen_port = port;
        grpc_listen_address = "127.0.0.1";
      };

      storage = {
        backend = "filesystem";
        filesystem.dir = "/var/lib/pyroscope/shared";
      };

      pyroscopedb = {
        data_path = "/var/lib/pyroscope/data";
        retention_policy_enforcement_interval = "5m";
        retention_policy_min_disk_available_percentage = 0.15;
        retention_policy_min_free_disk_gb = 15;
      };

      compactor = {
        data_dir = "/var/lib/pyroscope/compactor";
        blocks_retention_period = "336h";
        ring.store = "inmemory";
      };

      distributor.ring.store = "inmemory";
      ring.store = "inmemory";
      store_gateway.sharding_ring.store = "inmemory";
      query_scheduler.ring.store = "inmemory";
      overrides_exporter.ring.store = "inmemory";

      analytics.reporting_enabled = false;
    };
  };

  systemd.services.pyroscope = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
