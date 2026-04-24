{
  flake.nixosModules."monitoring-alloy-loki" =
    { config, lib, ... }:
    let
      inherit (lib)
        mkAfter
        mkOption
        types
        ;
      cfg = config.dsqr.nixos.alloy;
      lokiCfg = cfg.loki;
    in
    {
      options.dsqr.nixos.alloy.loki = {
        writeUrl = mkOption {
          type = types.str;
          default =
            if config.networking.hostName == "srv-lx-beacon" then
              "http://127.0.0.1:3100/loki/api/v1/push"
            else
              "http://10.10.30.102:3100/loki/api/v1/push";
          description = "Loki push endpoint on beacon";
        };

        journalMaxAge = mkOption {
          type = types.str;
          default = "24h";
          description = "How far back Alloy should read journald entries on startup.";
        };

        journalProcessStages = mkOption {
          type = types.lines;
          default = "";
          description = "Additional stages appended to the shared journald processing pipeline.";
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Additional Loki-related Alloy config appended after the shared journald pipeline.";
        };
      };

      config = {
        systemd.services.alloy.serviceConfig.SupplementaryGroups = mkAfter [ "systemd-journal" ];

        dsqr.nixos.alloy.configFragments = mkAfter [
          ''
            loki.write "beacon" {
              endpoint {
                url = "${lokiCfg.writeUrl}"
              }
            }

            loki.process "journal" {
              forward_to = [loki.write.beacon.receiver]

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
              forward_to    = [loki.write.beacon.receiver]
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
