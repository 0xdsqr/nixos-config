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
    extraFlags = [ "--retention-period=336h" ];
    settings = {
      target = "all";
      multitenancy_enabled = false;
      architecture_storage = "v2";
      show_banner = false;

      server = {
        http_listen_address = address;
        http_listen_port = port;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9097;
      };

      storage = {
        backend = "filesystem";
        filesystem.dir = "/var/lib/pyroscope/shared";
      };

      pyroscopedb = {
        data_path = "/var/lib/pyroscope/data";
      };

      analytics.reporting_enabled = false;
    };
  };

  systemd.services.pyroscope = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
