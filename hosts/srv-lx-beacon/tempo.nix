_:
let
  httpPort = 3200;
  grpcPort = 3201;
  otlpGrpcPort = 4317;
  otlpHttpPort = 4318;
in
{
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Tempo";
      uid = "tempo";
      type = "tempo";
      access = "proxy";
      url = "http://127.0.0.1:${toString httpPort}";
    }
  ];

  services.tempo = {
    enable = true;
    settings = {
      target = "all";

      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = httpPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = grpcPort;
      };

      backend_scheduler.local_work_path = "/var/lib/tempo/backend-scheduler";

      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "10.10.30.102:${toString otlpGrpcPort}";
        http.endpoint = "10.10.30.102:${toString otlpHttpPort}";
      };

      live_store = {
        shutdown_marker_dir = "/var/lib/tempo/live-store/shutdown-marker";
        wal.path = "/var/lib/tempo/live-store/traces";
      };

      storage.trace = {
        backend = "local";
        wal.path = "/var/lib/tempo/wal";
        local.path = "/var/lib/tempo/blocks";
      };

      backend_worker.compaction = {
        block_retention = "336h";
        compacted_block_retention = "1h";
        retention_concurrency = 1;
      };

      usage_report.reporting_enabled = false;
    };
  };
}
