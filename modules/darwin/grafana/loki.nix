{
  flake.darwinModules."grafana-alloy-loki" =
    { config, lib, ... }:
    let
      inherit (lib.lists) optional singleton;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf lines str;
      grafanaCfg = config.dsqr.darwin.grafana;
      alloyCfg = grafanaCfg.alloy;
      lokiCfg = grafanaCfg.loki;
    in
    {
      options.dsqr.darwin.grafana.loki = {
        enable = mkEnableOption "Grafana Alloy Loki log shipping";

        writeUrl = mkOption {
          type = str;
          default = "http://10.10.30.102:3100/loki/api/v1/push";
          description = "Loki push endpoint on beacon.";
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
        ];

        dsqr.darwin.grafana.alloy.extraFragments = mkIf (alloyCfg.enable && lokiCfg.enable) (
          mkAfter (
            singleton /* alloy */ ''
              loki.write "beacon" {
                endpoint {
                  url = "${lokiCfg.writeUrl}"
                }
              }

              loki.process "system_log" {
                forward_to = [loki.write.beacon.receiver]

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
                forward_to = [loki.write.beacon.receiver]

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
                forward_to = [loki.write.beacon.receiver]

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
