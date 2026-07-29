{ config, lib, ... }: {
  dsqr.nixos.alloy.loki.extraConfig = ''
    loki.process "opnsense_syslog" {
      forward_to = [loki.write.primary.receiver]

      stage.match {
        selector = "{job=\"opnsense-syslog\", app=\"filterlog\"}"

        stage.regex {
          expression = "^[0-9]+,(?:[^,]*,){4}(?P<interface>[^,]+),(?P<match_reason>[^,]+),(?P<action>pass|block),(?P<direction>in|out),.*$"
        }

        stage.labels {
          values = {
            action    = "",
            direction = "",
          }
        }

        stage.structured_metadata {
          values = {
            interface    = "",
            match_reason = "",
          }
        }
      }
    }

    loki.relabel "opnsense_syslog" {
      forward_to = [loki.process.opnsense_syslog.receiver]

      rule {
        source_labels = ["__syslog_connection_ip_address"]
        target_label  = "sender_ip"
      }

      rule {
        source_labels = ["__syslog_message_hostname"]
        target_label  = "host"
      }

      rule {
        source_labels = ["__syslog_message_app_name"]
        target_label  = "app"
      }

      rule {
        source_labels = ["__syslog_message_severity"]
        target_label  = "severity"
      }

      rule {
        source_labels = ["__syslog_message_facility"]
        target_label  = "facility"
      }
    }

    loki.source.syslog "opnsense" {
      listener {
        address                = "10.10.30.102:1514"
        protocol               = "tcp"
        syslog_format          = "rfc5424"
        use_incoming_timestamp = true
        labels = {
          job          = "opnsense-syslog",
          env          = "homelab",
          source       = "opnsense",
          role         = "firewall",
          service_name = "opnsense",
        }
      }

      forward_to    = [loki.process.opnsense_syslog.receiver]
      relabel_rules = loki.relabel.opnsense_syslog.rules
    }

    loki.source.syslog "proxmox" {
      listener {
        address                = "100.97.79.78:1515"
        protocol               = "tcp"
        syslog_format          = "rfc5424"
        use_incoming_timestamp = true
        labels = {
          job          = "proxmox-syslog",
          env          = "homelab",
          source       = "proxmox",
          role         = "hypervisor",
          service_name = "proxmox",
          instance     = "pve",
          host         = "pve",
          os           = "linux",
        }
      }

      forward_to = [loki.write.primary.receiver]
    }
  '';

  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Loki";
      uid = "loki";
      type = "loki";
      access = "proxy";
      url = "http://127.0.0.1:3100";
      jsonData = {
        maxLines = 5000;
        timeout = 30;
        derivedFields = [
          {
            name = "TraceID";
            matcherRegex = "(?:trace_id|traceID|traceId)[=\": ]+([a-fA-F0-9]{16,32})";
            datasourceUid = "tempo";
            url = "$${__value.raw}";
          }
        ];
      };
    }
  ];

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
        grpc_listen_address = "127.0.0.1";
      };

      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };

      frontend_worker.frontend_address = "127.0.0.1:9095";

      memberlist = {
        advertise_addr = "127.0.0.1";
        bind_addr = [ "127.0.0.1" ];
      };

      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config = {
        filesystem.directory = "/var/lib/loki/chunks";
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
          cache_location = "/var/lib/loki/index_cache";
        };
      };

      ingester = {
        chunk_encoding = "snappy";
        chunk_idle_period = "30m";
        chunk_retain_period = "1m";
        max_chunk_age = "2h";
        wal = {
          enabled = true;
          dir = "/var/lib/loki/wal";
        };
      };

      compactor = {
        compaction_interval = "10m";
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 10;
        delete_request_store = "filesystem";
      };

      limits_config = {
        allow_structured_metadata = true;
        creation_grace_period = "10m";
        discover_log_levels = true;
        ingestion_burst_size_mb = 16;
        ingestion_rate_mb = 8;
        max_entries_limit_per_query = 5000;
        max_query_length = "336h";
        max_query_lookback = "336h";
        max_query_parallelism = 8;
        query_timeout = "30s";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        retention_period = "336h";
        volume_enabled = true;
      };

      querier.max_concurrent = 4;

      analytics.reporting_enabled = false;
    };
  };

  systemd.services.loki-canary = {
    description = "Loki end-to-end write and query canary";
    after = [
      "loki.service"
      "network-online.target"
    ];
    wants = [
      "loki.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = lib.concatStringsSep " " [
        "${config.services.loki.package}/bin/loki-canary"
        "-addr=127.0.0.1:3100"
        "-push=true"
        "-port=3500"
        "-interval=30s"
        "-query-timeout=10s"
      ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      Restart = "always";
      RestartSec = "5s";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
    };
  };
}
