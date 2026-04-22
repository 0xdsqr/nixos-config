_: {
  services.grafana.provision.datasources.settings = {
    apiVersion = 1;
    datasources = [
      {
        name = "Prometheus";
        uid = "prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:9090";
        isDefault = true;
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
        job_name = "opnsense-node-exporter";
        static_configs = [
          {
            targets = [ "10.10.10.1:9100" ];
            labels = {
              host = "opnsense";
              role = "firewall";
              vlan = "mgmt";
              kind = "node-exporter";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "opnsense-telegraf";
        static_configs = [
          {
            targets = [ "10.10.10.1:9273" ];
            labels = {
              host = "opnsense";
              role = "firewall";
              vlan = "mgmt";
              kind = "telegraf";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "proxmox-node-exporter";
        static_configs = [
          {
            targets = [ "10.10.10.109:9100" ];
            labels = {
              host = "pve";
              role = "hypervisor";
              vlan = "mgmt";
              kind = "node-exporter";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "proxmox-api";
        static_configs = [
          {
            targets = [ "10.10.10.109:9221" ];
            labels = {
              host = "pve";
              role = "hypervisor";
              vlan = "mgmt";
              kind = "proxmox-api";
              env = "homelab";
            };
          }
        ];
        metrics_path = "/pve";
        params = {
          module = [ "default" ];
          cluster = [ "1" ];
          node = [ "1" ];
        };
      }
    ];
  };
}
