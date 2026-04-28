{ config, lib, ... }:
let
  inherit (lib) genAttrs;

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

  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ "/var/lib/tempo" ];
  });

  services.tempo = {
    enable = true;
    settings = {
      server = {
        http_listen_port = httpPort;
        grpc_listen_port = grpcPort;
      };

      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "0.0.0.0:${toString otlpGrpcPort}";
        http.endpoint = "0.0.0.0:${toString otlpHttpPort}";
      };

      storage.trace = {
        backend = "local";
        wal.path = "/var/lib/tempo/wal";
        local.path = "/var/lib/tempo/blocks";
      };

      usage_report.reporting_enabled = false;
    };
  };
}
