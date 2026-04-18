_: {
  services.grafana.provision.datasources.settings = {
    apiVersion = 1;
    prune = true;
    datasources = [
      {
        name = "Prometheus";
        uid = "prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:9090";
        isDefault = true;
        editable = false;
      }
    ];
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";
    extraFlags = [ "--web.enable-remote-write-receiver" ];
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "30s";
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:9090" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "postgres-khaos";
        static_configs = [
          {
            targets = [ "192.168.50.71:9187" ];
            labels = {
              role = "khaos";
              kind = "postgres";
              env = "homelab";
            };
          }
        ];
      }
    ];
  };
}
