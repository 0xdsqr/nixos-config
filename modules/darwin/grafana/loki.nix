{
  flake.darwinModules."grafana-alloy-loki" =
    { config, lib, ... }:
    let
      inherit (lib.lists) optional singleton;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        listOf
        lines
        nullOr
        str
        ;
      grafanaCfg = config.dsqr.darwin.grafana;
      alloyCfg = grafanaCfg.alloy;
      lokiCfg = grafanaCfg.loki;
    in
    {
      options.dsqr.darwin.grafana.loki = {
        enable = mkEnableOption "Grafana Alloy Loki log shipping";

        writeUrl = mkOption {
          type = nullOr str;
          default = null;
          description = "Loki push endpoint.";
        };

        extraFragments = mkOption {
          type = listOf lines;
          default = [ ];
          description = "Additional Loki-related Alloy config appended after the generated Darwin log pipeline.";
        };

        exo = {
          enable = mkEnableOption "Exo log shipping";

          user = mkOption {
            type = str;
            default = config.dsqr.darwin.personal.user.name;
            description = "User account running the Exo launchd agent.";
          };

          logPath = mkOption {
            type = str;
            default = "/Users/${lokiCfg.exo.user}/Library/Logs/exo/exo.log";
            description = "Exo log file tailed by Alloy.";
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = (!lokiCfg.enable) || alloyCfg.enable;
            message = "dsqr.darwin.grafana.loki.enable requires dsqr.darwin.grafana.alloy.enable.";
          }
          {
            assertion = (!lokiCfg.enable) || lokiCfg.writeUrl != null;
            message = "dsqr.darwin.grafana.loki.writeUrl must be set when dsqr.darwin.grafana.loki.enable is true.";
          }
        ];

        dsqr.darwin.grafana.alloy.extraFragments = mkIf (alloyCfg.enable && lokiCfg.enable) (
          mkAfter (
            singleton /* alloy */ ''
              loki.write "primary" {
                endpoint {
                  url                 = "${if lokiCfg.writeUrl == null then "" else lokiCfg.writeUrl}"
                  min_backoff_period  = "500ms"
                  max_backoff_period  = "30s"
                  max_backoff_retries = 20
                  retry_on_http_429   = true
                  remote_timeout      = "10s"
                }

                wal {
                  enabled            = true
                  drain_timeout      = "30s"
                  min_read_frequency = "250ms"
                  max_read_frequency = "1s"
                  max_segment_age    = "1h"
                }
              }

              loki.process "system_log" {
                forward_to = [loki.write.primary.receiver]

                stage.regex {
                  expression = "^[A-Z][a-z]{2} +\\d{1,2} \\d{2}:\\d{2}:\\d{2} \\S+ (?P<unit>[^\\[]+?)(?:\\[(?P<pid>\\d+)\\])?: (?P<message>.*)$"
                }

                stage.labels {
                  values = {
                    unit = "",
                  }
                }
              }

              loki.source.file "system_log" {
                targets = [
                  {
                    __path__   = "/var/log/system.log",
                    "job"      = "system-log",
                    "instance" = "${alloyCfg.instance}",
                    "host"     = "${alloyCfg.instance}",
                    "role"     = "${alloyCfg.role}",
                    "env"      = "${alloyCfg.environment}",
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
                    "instance" = "${alloyCfg.instance}",
                    "host"     = "${alloyCfg.instance}",
                    "role"     = "${alloyCfg.role}",
                    "env"      = "${alloyCfg.environment}",
                    "os"       = "macos",
                  },
                ]
                forward_to = [loki.write.primary.receiver]

                file_match {
                  enabled = true
                }
              }
            ''
            ++ optional lokiCfg.exo.enable /* alloy */ ''
              loki.source.file "exo_log" {
                targets = [
                  {
                    __path__   = "${lokiCfg.exo.logPath}",
                    "job"      = "exo",
                    "unit"     = "exo",
                    "instance" = "${alloyCfg.instance}",
                    "host"     = "${alloyCfg.instance}",
                    "role"     = "${alloyCfg.role}",
                    "env"      = "${alloyCfg.environment}",
                    "os"       = "macos",
                  },
                ]
                forward_to = [loki.write.primary.receiver]

                file_match {
                  enabled = true
                }
              }
            ''
            ++ lokiCfg.extraFragments
          )
        );
      };
    };
}
