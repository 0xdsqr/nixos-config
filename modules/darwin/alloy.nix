{
  flake.darwinModules.alloy =
    {
      config,
      hostName,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        optionalString
        types
        ;
      cfg = config.dsqr.darwin.alloy;

      alloyConfig = pkgs.writeText "config.alloy" (
        ''
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
              replacement  = "mac-mini"
            }

            rule {
              target_label = "env"
              replacement  = "homelab"
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
              url  = "${cfg.remoteWriteUrl}"
            }
          }
        ''
        + optionalString cfg.loki.enable ''
          loki.write "beacon" {
            endpoint {
              url = "${cfg.loki.writeUrl}"
            }
          }

          // Simple macOS host logging baseline:
          // - /var/log/system.log for host-level system events
          // - the Alloy daemon log for agent troubleshooting
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
                "role"     = "mac-mini",
                "env"      = "homelab",
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
                "role"     = "mac-mini",
                "env"      = "homelab",
                "os"       = "macos",
              },
            ]
            forward_to = [loki.write.beacon.receiver]

            file_match {
              enabled = true
            }
          }
        ''
      );
    in
    {
      options.dsqr.darwin.alloy = {
        enable = mkEnableOption "Enable Alloy-based host monitoring on Darwin hosts";

        instance = mkOption {
          type = types.str;
          default = hostName;
          description = "Stable instance label for this host";
        };

        remoteWriteUrl = mkOption {
          type = types.str;
          default = "http://10.10.30.102:9090/api/v1/write";
          description = "Prometheus remote_write receiver URL on beacon";
        };

        loki = {
          enable = mkEnableOption "Enable Loki log shipping through Alloy on Darwin hosts";

          writeUrl = mkOption {
            type = types.str;
            default = "http://10.10.30.102:3100/loki/api/v1/push";
            description = "Loki push endpoint on beacon";
          };
        };
      };

      config = mkIf cfg.enable {
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
      };
    };
}
