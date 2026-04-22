{
  flake.nixosModules."monitoring-alloy-loki" =
    { config, lib, ... }:
    let
      inherit (lib) mkAfter mkIf optionals;
      cfg = config.dsqr.nixos.alloy;
      lokiCfg = cfg.loki;
    in
    {
      config = mkIf (cfg.enable && lokiCfg.enable) {
        systemd.services.alloy.serviceConfig.SupplementaryGroups = mkAfter (optionals lokiCfg.enable [ "systemd-journal" ]);

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
