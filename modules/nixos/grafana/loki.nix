{
  flake.nixosModules."monitoring-alloy-loki" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) lines nullOr str;
      cfg = config.dsqr.nixos.alloy;
      lokiCfg = cfg.loki;
    in
    {
      options.dsqr.nixos.alloy.loki = {
        enable = mkEnableOption "Enable Alloy Loki journal shipping";

        writeUrl = mkOption {
          type = nullOr str;
          default = null;
          description = "Loki push endpoint.";
        };

        journalMaxAge = mkOption {
          type = str;
          default = "24h";
          description = "How far back Alloy should read journald entries on startup.";
        };

        journalProcessStages = mkOption {
          type = lines;
          default = "";
          description = "Additional stages appended to the shared journald processing pipeline.";
        };

        extraConfig = mkOption {
          type = lines;
          default = "";
          description = "Additional Loki-related Alloy config appended after the shared journald pipeline.";
        };
      };

      config = mkIf (cfg.enable && lokiCfg.enable) {
        assertions = [
          {
            assertion = lokiCfg.writeUrl != null;
            message = "dsqr.nixos.alloy.loki.writeUrl must be set when dsqr.nixos.alloy.loki.enable is true.";
          }
        ];

        systemd.services.alloy.serviceConfig.SupplementaryGroups = mkAfter [ "systemd-journal" ];

        dsqr.nixos.alloy.configFragments = mkAfter [
          ''
            loki.write "primary" {
              endpoint {
                url = "${if lokiCfg.writeUrl == null then "" else lokiCfg.writeUrl}"
              }
            }

            loki.process "journal" {
              forward_to = [loki.write.primary.receiver]

              ${lokiCfg.journalProcessStages}
            }

            loki.relabel "journal" {
              forward_to = [loki.process.journal.receiver]

              rule {
                source_labels = ["__journal__systemd_unit"]
                target_label  = "unit"
              }

              rule {
                source_labels = ["__journal_priority_keyword"]
                target_label  = "level"
              }

              rule {
                source_labels = ["__journal__systemd_unit"]
                regex         = "cloudflared-managed-tunnel\\.service"
                target_label  = "service_name"
                replacement   = "cloudflared"
              }
            }

            loki.source.journal "systemd" {
              forward_to    = [loki.write.primary.receiver]
              relabel_rules = loki.relabel.journal.rules
              max_age       = "${lokiCfg.journalMaxAge}"

              labels = {
                "job"      = "systemd-journal",
                "instance" = "${cfg.instance}",
                "host"     = "${cfg.instance}",
                "role"     = "${cfg.role}",
                "env"      = "${cfg.environment}",
                "os"       = "linux",
              }
            }

            ${lokiCfg.extraConfig}
          ''
        ];
      };
    };
}
