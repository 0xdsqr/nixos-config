_: {
  dsqr.nixos.alloy.loki.extraConfig = ''
    loki.process "opnsense_syslog" {
      forward_to = [loki.write.beacon.receiver]

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
        address                = "0.0.0.0:1514"
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

      forward_to    = [loki.write.beacon.receiver]
      relabel_rules = loki.relabel.opnsense_syslog.rules
    }
  '';

  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Loki";
      uid = "loki";
      type = "loki";
      access = "proxy";
      url = "http://127.0.0.1:3100";
    }
  ];

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = 3100;
      };

      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
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
    };
  };
}
