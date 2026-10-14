_:
let
  address = "10.10.30.102";
  port = 9009;
in
{
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Mimir";
      uid = "mimir";
      type = "prometheus";
      access = "proxy";
      url = "http://${address}:${toString port}/prometheus";
      isDefault = false;
      jsonData = {
        httpMethod = "POST";
        prometheusType = "Mimir";
      };
    }
  ];

  services.mimir = {
    enable = true;
    configuration = {
      target = "all";
      multitenancy_enabled = false;

      server = {
        http_listen_address = address;
        http_listen_port = port;
        grpc_listen_address = "0.0.0.0";
        grpc_listen_port = 9096;
      };

      memberlist = {
        bind_addr = [ "127.0.0.1" ];
        bind_port = 7947;
      };

      blocks_storage = {
        backend = "filesystem";
        filesystem.dir = "/var/lib/mimir/blocks";
        tsdb.dir = "/var/lib/mimir/tsdb";
        bucket_store.sync_dir = "/var/lib/mimir/tsdb-sync";
      };

      compactor = {
        data_dir = "/var/lib/mimir/compactor";
      };

      limits = {
        compactor_blocks_retention_period = "336h";
        # Single shared tenant on the 8 GiB Beacon host. October 5 measurement:
        # ~252k active Prometheus series before Indigo source filtering, ~191k
        # projected afterwards; ~10k appended samples/s before filtering.
        # Keep finite headroom for churn, additional core scrapes, and WAL replay.
        # These are admission budgets, not a memory reservation or HA guarantee.
        max_global_series_per_user = 300000;
        ingestion_rate = 20000;
        ingestion_burst_size = 200000;
      };

      ingester.ring = {
        kvstore.store = "inmemory";
        replication_factor = 1;
        min_ready_duration = "0s";
        final_sleep = "0s";
      };

      distributor.ring.kvstore.store = "inmemory";
      store_gateway.sharding_ring.kvstore.store = "inmemory";
      ruler.ring.kvstore.store = "inmemory";
      alertmanager.sharding_ring.kvstore.store = "inmemory";

      ruler_storage = {
        backend = "local";
        local.directory = "/var/lib/mimir/rules";
      };

      alertmanager_storage = {
        backend = "filesystem";
        filesystem.dir = "/var/lib/mimir/alertmanager";
      };

      activity_tracker.filepath = "/var/lib/mimir/activity.log";
      usage_stats.enabled = false;
    };
  };

  systemd.services.mimir = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    preStart = ''
      mkdir -p /var/lib/mimir/alertmanager /var/lib/mimir/rules
    '';
  };
}
