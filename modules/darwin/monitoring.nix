{
  flake.darwinModules =
    let
      baseFragment = cfg: ''
        prometheus.exporter.unix "host" {}

        prometheus.relabel "host" {
          forward_to = [prometheus.remote_write.beacon.receiver]

          rule {
            target_label = "instance"
            replacement  = "${cfg.instance}"
          }

          rule {
            target_label = "host"
            replacement  = "${cfg.instance}"
          }

          rule {
            target_label = "role"
            replacement  = "${cfg.role}"
          }

          rule {
            target_label = "env"
            replacement  = "${cfg.environment}"
          }

          rule {
            target_label = "os"
            replacement  = "macos"
          }
        }

        prometheus.scrape "host" {
          targets         = prometheus.exporter.unix.host.targets
          scrape_interval = "15s"
          forward_to      = [prometheus.relabel.host.receiver]
        }

        prometheus.remote_write "beacon" {
          endpoint {
            name = "beacon"
            url  = "${cfg.prometheus.remoteWriteUrl}"
          }
        }
      '';

      lokiFragment = cfg: ''
        loki.write "beacon" {
          endpoint {
            url = "${cfg.loki.writeUrl}"
          }
        }

        loki.process "system_log" {
          forward_to = [loki.write.beacon.receiver]

          stage.regex {
            expression = "^[A-Z][a-z]{2} +\\d{1,2} \\d{2}:\\d{2}:\\d{2} \\S+ (?P<unit>[^\\[]+?)(?:\\[(?P<pid>\\d+)\\])?: (?P<message>.*)$"
          }

          stage.labels {
            values = {
              unit = ""
            }
          }
        }

        loki.source.file "system_log" {
          targets = [
            {
              __path__   = "/var/log/system.log",
              "job"      = "system-log",
              "instance" = "${cfg.instance}",
              "host"     = "${cfg.instance}",
              "role"     = "${cfg.role}",
              "env"      = "${cfg.environment}",
              "os"       = "macos",
            },
          ]
          forward_to = [loki.process.system_log.receiver]

          file_match {
            enabled = true
          }
        }

        loki.source.file "alloy_log" {
          targets = [
            {
              __path__   = "/var/log/grafana-alloy/alloy.log",
              "job"      = "grafana-alloy",
              "unit"     = "grafana-alloy",
              "instance" = "${cfg.instance}",
              "host"     = "${cfg.instance}",
              "role"     = "${cfg.role}",
              "env"      = "${cfg.environment}",
              "os"       = "macos",
            },
          ]
          forward_to = [loki.write.beacon.receiver]

          file_match {
            enabled = true
          }
        }
      '';
    in
    {
      "monitoring-alloy-base" =
        {
          config,
          hostName,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (lib)
            concatStringsSep
            mkAfter
            mkMerge
            mkOption
            types
            ;
          cfg = config.dsqr.darwin.monitoring;
          alloyConfig = pkgs.writeText "config.alloy" (concatStringsSep "\n\n" cfg.configFragments);
        in
        {
          options.dsqr.darwin.monitoring = {
            instance = mkOption {
              type = types.str;
              default = hostName;
              description = "Stable instance label for this host";
            };

            role = mkOption {
              type = types.str;
              default = hostName;
              description = "Role label for this host";
            };

            environment = mkOption {
              type = types.str;
              default = "homelab";
              description = "Environment label for this host";
            };

            configFragments = mkOption {
              type = types.listOf types.lines;
              default = [ ];
              internal = true;
              description = "Internal Alloy config fragments composed by monitoring modules.";
            };

            prometheus = {
              remoteWriteUrl = mkOption {
                type = types.str;
                default = "http://10.10.30.102:9090/api/v1/write";
                description = "Prometheus remote_write receiver URL on beacon";
              };
            };

            loki = {
              writeUrl = mkOption {
                type = types.str;
                default = "http://10.10.30.102:3100/loki/api/v1/push";
                description = "Loki push endpoint on beacon";
              };
            };
          };

          config = mkMerge [
            {
              environment.systemPackages = [ pkgs.grafana-alloy ];

              system.activationScripts.preActivation.text = ''
                mkdir -p /var/lib/grafana-alloy
                mkdir -p /var/log/grafana-alloy
              '';

              launchd.daemons.grafana-alloy = {
                serviceConfig = {
                  KeepAlive = true;
                  RunAtLoad = true;
                  WorkingDirectory = "/var/lib/grafana-alloy";
                  StandardOutPath = "/var/log/grafana-alloy/alloy.log";
                  StandardErrorPath = "/var/log/grafana-alloy/alloy.log";
                  ProgramArguments = [
                    "${pkgs.grafana-alloy}/bin/alloy"
                    "run"
                    "--storage.path=/var/lib/grafana-alloy"
                    "--server.http.listen-addr=127.0.0.1:12345"
                    "${alloyConfig}"
                  ];
                };
              };

              dsqr.darwin.monitoring.configFragments = mkAfter [ (baseFragment cfg) ];
            }
          ];
        };

      "monitoring-alloy-loki" =
        { config, lib, ... }:
        let
          inherit (lib) mkAfter;
          cfg = config.dsqr.darwin.monitoring;
        in
        {
          config.dsqr.darwin.monitoring.configFragments = mkAfter [ (lokiFragment cfg) ];
        };
    };
}
