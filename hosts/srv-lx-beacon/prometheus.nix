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
    listenAddress = "0.0.0.0";
    port = 9090;
    retentionTime = "14d";
    webExternalUrl = "https://prometheus.home.arpa/";
    remoteWrite = [
      {
        name = "mimir";
        url = "http://10.10.30.102:9009/api/v1/push";
      }
    ];
    extraFlags = [
      "--storage.tsdb.retention.size=40GB"
      "--web.enable-remote-write-receiver"
    ];
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "30s";
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "10.10.30.102:9090" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "loki";
        static_configs = [
          {
            targets = [ "127.0.0.1:3100" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "loki-canary";
        static_configs = [
          {
            targets = [ "127.0.0.1:3500" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "alloy";
        static_configs = [
          {
            targets = [ "127.0.0.1:12345" ];
            labels = {
              role = "beacon";
              kind = "collector";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "grafana";
        static_configs = [
          {
            targets = [ "10.10.30.102:8000" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "tempo";
        static_configs = [
          {
            targets = [ "127.0.0.1:3200" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "mimir";
        static_configs = [
          {
            targets = [ "10.10.30.102:9009" ];
            labels = {
              role = "beacon";
              kind = "service";
              env = "homelab";
            };
          }
        ];
      }
      {
        job_name = "pyroscope";
        static_configs = [
          {
            targets = [ "10.10.30.102:4040" ];
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

  systemd.services.prometheus = {
    after = [
      "mimir.service"
      "network-online.target"
    ];
    wants = [
      "mimir.service"
      "network-online.target"
    ];
  };
}
